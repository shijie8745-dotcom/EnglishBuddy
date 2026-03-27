import Foundation
import AVFoundation
import Combine

/// 阿里云 Qwen TTS 实时流式语音合成服务
/// 使用 WebSocket 实现 qwen3-tts-flash-realtime 模型的流式语音合成
final class QwenTTSRealtimeService: NSObject, ObservableObject {
    static let shared = QwenTTSRealtimeService()

    // MARK: - Published Properties

    @Published var isReady = false
    @Published var isPlaying = false
    @Published var isConnecting = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey: String = APIConfig.dashScopeAPIKey
    private let baseURL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime"
    private let model = "qwen3-tts-instruct-flash-realtime"

    // 音频引擎
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?

    // 音频数据累积（用于缓存）
    private var accumulatedAudioData = Data()

    // 音频数据是否接收完成
    private var isDataComplete = false

    // 回调
    var onAudioChunk: ((Data) -> Void)?
    var onComplete: ((Data) -> Void)?  // 音频数据接收完成
    var onPlaybackComplete: (() -> Void)?  // 音频播放完成
    var onError: ((Error) -> Void)?
    var onPlayingStateChanged: ((Bool) -> Void)?  // 播放状态变化

    // 连接完成的 continuation
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    // session 更新完成的 continuation
    private var sessionUpdateContinuation: CheckedContinuation<Void, Error>?

    // 音频块播放追踪
    private var pendingBufferCount: Int = 0
    private var isLastBuffer: Bool = false
    private var hasPlaybackCompleted: Bool = false  // 防止重复触发

    // 音频会话中断追踪
    private var wasPlayingBeforeInterruption: Bool = false

    // MARK: - Initialization

    private override init() {
        super.init()
        setupInterruptionObserver()
    }

    /// 监听音频会话中断通知
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // 中断开始（电话、闹钟等）
            print("[QwenTTS] 音频会话中断开始")
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                // 停止播放，确保回调在主线程触发
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playerNode?.stop()
                    self.audioEngine?.pause()
                    self.isPlaying = false
                    self.onPlayingStateChanged?(false)
                    print("[QwenTTS] 中断时已停止播放并通知 UI")
                }
            }

        case .ended:
            // 中断结束 - 重新激活音频会话
            print("[QwenTTS] 音频会话中断结束，重新激活音频会话")
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("[QwenTTS] 音频会话已重新激活")

                // 如果音频引擎存在但未运行，尝试重新启动
                if let engine = audioEngine, !engine.isRunning {
                    try engine.start()
                    print("[QwenTTS] 音频引擎已重新启动")
                }
            } catch {
                print("[QwenTTS] 恢复音频会话失败: \(error)")
            }
            wasPlayingBeforeInterruption = false

        @unknown default:
            break
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let cont = connectionContinuation {
            cont.resume(throwing: TTSSError.notConnected)
        }
        close()
    }

    // MARK: - Public Methods

    /// 连接到 WebSocket 服务
    func connect() async throws {
        // 清理旧连接（即使状态是 running，也强制重新连接）
        let oldTask = webSocketTask
        webSocketTask = nil
        oldTask?.cancel(with: .normalClosure, reason: nil)

        // 等待旧连接关闭
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒

        isConnecting = true
        errorMessage = nil

        // 构建 URL，包含 model 查询参数
        let urlString = "\(baseURL)?model=\(model)"
        guard let url = URL(string: urlString) else {
            throw TTSSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.delegate = self

        webSocketTask?.resume()

        // 等待连接建立
        try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
            // 设置超时
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                if let cont = self?.connectionContinuation {
                    self?.connectionContinuation = nil
                    cont.resume(throwing: TTSSError.connectionTimeout)
                }
            }
        }

        isConnecting = false

        // 初始化音频引擎
        setupAudioEngine()

        // 开始接收消息
        startReceiving()
    }

    /// 预连接 WebSocket（在进入页面时调用）
    func prepare() async {
        guard !isReady && !isConnecting else { return }

        do {
            try await connect()
        } catch {
            print("[QwenTTS] 预连接失败: \(error.localizedDescription)")
            isReady = false
            isConnecting = false
        }
    }

    /// 配置会话
    func updateSession(voice: String = "Cherry") async throws {
        guard webSocketTask?.state == .running else {
            throw TTSSError.notConnected
        }

        // 简化配置，只保留必要的参数
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "mode": "server_commit",
                "voice": voice
            ]
        ]

        try await sendJSON(sessionUpdate)

        // 等待 session.updated 确认
        try await withCheckedThrowingContinuation { continuation in
            self.sessionUpdateContinuation = continuation
            // 设置超时
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                if let cont = self?.sessionUpdateContinuation {
                    self?.sessionUpdateContinuation = nil
                    cont.resume(throwing: TTSSError.connectionTimeout)
                }
            }
        }

        isReady = true
        print("[QwenTTS] Session 更新成功")
    }

    /// 发送文本进行语音合成
    func appendText(_ text: String) async throws {
        guard webSocketTask?.state == .running else {
            throw TTSSError.notConnected
        }

        // 注意：官方 API 不需要 event_id 字段
        let message: [String: Any] = [
            "type": "input_text_buffer.append",
            "text": text
        ]

        try await sendJSON(message)
        print("[QwenTTS] 发送文本: \(text.prefix(50))...")
    }

    /// 结束会话
    func finish() {
        // 注意：官方 API 不需要 event_id 字段
        let message: [String: Any] = [
            "type": "session.finish"
        ]
        sendJSON(message)
        print("[QwenTTS] 发送 session.finish")
    }

    /// 关闭连接
    func close() {
        // 清理 continuation
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: TTSSError.notConnected)
        }
        if let cont = sessionUpdateContinuation {
            sessionUpdateContinuation = nil
            cont.resume(throwing: TTSSError.notConnected)
        }

        // 先清理引用，再关闭连接
        let taskToClose = webSocketTask
        webSocketTask = nil

        taskToClose?.cancel(with: .normalClosure, reason: nil)

        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil

        isReady = false
        isConnecting = false
        isPlaying = false
    }

    /// 停止播放（保留音频会话以便 ASR 可以直接使用）
    func stop() {
        // 重置音频块追踪状态
        pendingBufferCount = 0
        isLastBuffer = false
        hasPlaybackCompleted = true  // 标记已处理，防止后续 completion 触发

        // 停止播放节点
        playerNode?.stop()

        // 停止音频引擎
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)  // 确保释放输入 tap

        if isPlaying {
            isPlaying = false
            onPlayingStateChanged?(false)
        }
        print("[QwenTTS] 播放已停止（音频会话保持 playAndRecord 模式）")
    }

    /// 重置状态（用于新的合成任务）
    func reset() {
        // 重置音频块追踪状态
        pendingBufferCount = 0
        isLastBuffer = false
        hasPlaybackCompleted = false

        // 先记录要关闭的任务
        let taskToClose = webSocketTask

        // 清理 continuation，避免关闭连接时影响新连接
        connectionContinuation = nil
        sessionUpdateContinuation = nil

        // 先清理引用，再关闭连接（避免委托回调干扰）
        webSocketTask = nil

        accumulatedAudioData = Data()
        errorMessage = nil
        isPlaying = false
        isReady = false
        isConnecting = false
        isDataComplete = false

        // 最后关闭旧连接
        taskToClose?.cancel(with: .normalClosure, reason: nil)
    }

    // MARK: - Private Methods

    /// 初始化音频引擎
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioEngine!.attach(playerNode!)

        // PCM 24000Hz Mono Float32 (非交错模式，更稳定)
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        )

        guard let format = audioFormat else { return }
        audioEngine!.connect(playerNode!, to: audioEngine!.mainMixerNode, format: format)

        // 配置音频会话 - 使用 playAndRecord 模式以便与 ASR 兼容
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[QwenTTS] 音频会话已配置为 playAndRecord（兼容 ASR）")
        } catch {
            print("[QwenTTS] 音频会话配置失败: \(error)")
        }

        try? audioEngine!.start()
        print("[QwenTTS] 音频引擎已启动，采样率: \(format.sampleRate)")
    }

    /// 发送 JSON 消息
    private func sendJSON(_ dict: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: dict)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw TTSSError.encodingFailed
        }
        try await webSocketTask?.send(.string(jsonString))
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("[QwenTTS] 发送失败: \(error)")
            }
        }
    }

    /// 开始接收消息
    private func startReceiving() {
        print("[QwenTTS] 开始接收消息循环")
        // 检查当前任务的引用，避免在旧任务上接收
        let currentTask = webSocketTask
        currentTask?.receive { [weak self] result in
            guard let self = self else { return }

            // 确保我们还在处理同一个任务
            guard self.webSocketTask === currentTask else {
                print("[QwenTTS] 忽略旧任务的接收回调")
                return
            }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.startReceiving()

            case .failure(let error):
                print("[QwenTTS] 接收错误: \(error)")
                DispatchQueue.main.async {
                    self.onError?(error)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// 处理接收到的消息
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        var messageData: Data?

        switch message {
        case .data(let data):
            messageData = data
        case .string(let text):
            messageData = text.data(using: .utf8)
        @unknown default:
            return
        }

        guard let data = messageData,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("[QwenTTS] 无法解析消息")
            return
        }

        // 打印收到的消息类型（调试用）
        print("[QwenTTS] 收到消息类型: \(type)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch type {
            case "session.created":
                print("[QwenTTS] 会话创建成功")
                if let session = json["session"] as? [String: Any],
                   let sessionId = session["id"] as? String {
                    print("[QwenTTS] Session ID: \(sessionId)")
                }

            case "session.updated":
                print("[QwenTTS] 会话更新确认")
                if let cont = self.sessionUpdateContinuation {
                    self.sessionUpdateContinuation = nil
                    cont.resume()
                }

            case "response.audio.delta":
                // 收到音频数据块
                print("[QwenTTS] 收到音频数据块")
                if let audioBase64 = json["delta"] as? String {
                    print("[QwenTTS] audioBase64 长度: \(audioBase64.count)")
                    if let audioData = Data(base64Encoded: audioBase64) {
                        print("[QwenTTS] 解码成功，音频数据长度: \(audioData.count)")
                        self.accumulatedAudioData.append(audioData)
                        self.playAudioChunk(audioData)
                        self.onAudioChunk?(audioData)
                    } else {
                        print("[QwenTTS] Base64 解码失败")
                    }
                } else {
                    print("[QwenTTS] 未找到 delta 字段，json: \(json)")
                }

            case "response.done":
                print("[QwenTTS] 响应完成")

            case "session.finished":
                print("[QwenTTS] 会话结束，累积音频长度: \(self.accumulatedAudioData.count)")

                // 标记数据接收完成
                self.isDataComplete = true

                // 将 PCM 数据转换为 WAV 格式（用于 AVAudioPlayer 播放）
                let pcmData = self.accumulatedAudioData
                let wavData = self.createWavDataFromPCM(pcmData)
                print("[QwenTTS] WAV 数据长度: \(wavData.count)")
                print("[QwenTTS] 准备调用 onComplete 回调")
                self.onComplete?(wavData)
                print("[QwenTTS] onComplete 回调已执行")

                // 标记最后一个音频块，播放完成后触发回调
                self.isLastBuffer = true

                // 如果没有待播放的音频块，直接触发播放完成
                if self.pendingBufferCount == 0 && !self.hasPlaybackCompleted {
                    self.hasPlaybackCompleted = true
                    print("[QwenTTS] 没有待播放的音频块，直接结束播放")
                    self.isPlaying = false
                    self.onPlayingStateChanged?(false)
                }

            case "error":
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("[QwenTTS] 服务器错误: \(message)")
                    self.errorMessage = message
                    self.onError?(TTSSError.serverError(message))
                } else {
                    print("[QwenTTS] 错误消息: \(json)")
                }

            default:
                print("[QwenTTS] 未处理的消息类型: \(type), json: \(json)")
            }
        }
    }

    /// 播放音频块
    private func playAudioChunk(_ data: Data) {
        guard let format = audioFormat,
              let engine = audioEngine,
              let player = playerNode else { return }

        // 确保音频引擎正在运行（可能被系统中断后停止）
        if !engine.isRunning {
            do {
                // 重新激活音频会话（使用与 ASR 兼容的模式）
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

                try engine.start()
                print("[QwenTTS] 音频引擎重新启动")
            } catch {
                print("[QwenTTS] 音频引擎启动失败: \(error)")
                return
            }
        }

        let frameCount = UInt32(data.count / 2)  // 16bit = 2 bytes per sample
        guard frameCount > 0 else { return }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount

        // 将 Int16 PCM 转换为 Float32
        data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            let int16Ptr = baseAddress.assumingMemoryBound(to: Int16.self)

            // Float32 范围是 -1.0 到 1.0，Int16 范围是 -32768 到 32767
            for i in 0..<Int(frameCount) {
                let sample = int16Ptr[i]
                buffer.floatChannelData![0][i] = Float(sample) / 32768.0
            }
        }

        // 增加待播放计数
        pendingBufferCount += 1

        player.scheduleBuffer(buffer, at: nil, options: []) {
            // 音频块播放完成
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.pendingBufferCount -= 1

                // 检查是否所有块播放完成且会话已结束
                if self.isLastBuffer && self.pendingBufferCount == 0 && !self.hasPlaybackCompleted {
                    self.hasPlaybackCompleted = true
                    print("[QwenTTS] 最后一个音频块播放完成")
                    self.isPlaying = false
                    self.onPlayingStateChanged?(false)
                }
            }
        }

        if !player.isPlaying {
            player.play()
            isPlaying = true
            onPlayingStateChanged?(true)
        }
    }

    /// 将 PCM 数据转换为 WAV 格式
    private func createWavDataFromPCM(_ pcmData: Data) -> Data {
        var wavData = Data()

        let sampleRate: UInt32 = 24000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate: UInt32 = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign: UInt16 = channels * bitsPerSample / 8
        let dataSize: UInt32 = UInt32(pcmData.count)
        let fileSize: UInt32 = 36 + dataSize

        // RIFF header
        wavData.append(contentsOf: "RIFF".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        wavData.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        wavData.append(contentsOf: "fmt ".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })  // Chunk size
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })   // Audio format (PCM)
        wavData.append(contentsOf: withUnsafeBytes(of: channels.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data chunk
        wavData.append(contentsOf: "data".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        wavData.append(pcmData)

        return wavData
    }
}

// MARK: - URLSessionWebSocketDelegate

extension QwenTTSRealtimeService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // 只处理当前任务的回调
        guard webSocketTask === self.webSocketTask else {
            print("[QwenTTS] 忽略旧任务的连接打开回调")
            return
        }
        print("[QwenTTS] WebSocket 连接已打开")

        // 恢复等待连接的 continuation
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // 只处理当前任务的回调
        guard webSocketTask === self.webSocketTask else {
            print("[QwenTTS] 忽略旧任务的连接关闭回调")
            return
        }
        print("[QwenTTS] WebSocket 连接已关闭: \(closeCode)")

        // 如果有等待的 continuation，恢复它并抛出错误
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: TTSSError.notConnected)
        }

        DispatchQueue.main.async {
            self.isReady = false
            self.isPlaying = false
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 只处理当前任务的回调
        guard task === self.webSocketTask else {
            print("[QwenTTS] 忽略旧任务的任务完成回调")
            return
        }
        if let error = error {
            print("[QwenTTS] WebSocket 任务错误: \(error)")

            // 如果有等待的 continuation，恢复它并抛出错误
            if let cont = connectionContinuation {
                connectionContinuation = nil
                cont.resume(throwing: error)
            }

            DispatchQueue.main.async {
                self.isConnecting = false
                self.isReady = false
                self.errorMessage = error.localizedDescription
                self.onError?(error)
            }
        }
    }
}

// MARK: - Error Types

enum TTSSError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case connectionTimeout
    case encodingFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .notConnected:
            return "WebSocket 未连接"
        case .connectionTimeout:
            return "连接超时"
        case .encodingFailed:
            return "编码失败"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}