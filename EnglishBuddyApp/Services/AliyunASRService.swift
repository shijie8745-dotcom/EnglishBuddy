import Foundation
import AVFAudio
import Combine

/// 阿里云实时语音识别服务 (qwen3-asr-flash-realtime-2026-02-10)
/// 使用 WebSocket API 进行实时语音转文字
final class AliyunASRService: NSObject, ObservableObject {
    static let shared = AliyunASRService()

    @Published var transcript = ""

    /// 标记当前会话是否已被取消（用于忽略取消后仍到达的异步消息）
    private var isSessionCancelled = false

    /// 标记是否检测到有效音频（音量超过阈值且持续足够帧数）
    private var hasValidAudio = false

    /// 音量超过阈值的帧数计数
    private var validAudioFrameCount: Int = 0

    /// 音量阈值（低于此值视为静音）
    private let volumeThreshold: Float = 0.05

    /// 需要连续超过阈值的最少帧数（约 0.3 秒，取决于音频回调频率）
    private let minValidFrameCount: Int = 3

    /// ASR 常见噪音幻觉短语（环境噪音容易被误识别为这些内容）
    private let hallucinationPhrases: Set<String> = [
        "thank you", "thank you.", "thanks.", "thanks",
        "you", "you.", "bye.", "bye", "yeah.", "yeah",
        "the", "the.", "a", "i", "hmm", "hmm.",
        "uh", "uh.", "um", "um.", "oh", "oh.",
    ]
    @Published var isRecording = false
    @Published var isConnecting = false
    @Published var isReady = false  // WebSocket 已连接并准备好录音
    @Published var errorMessage: String?

    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?

    // MARK: - Configuration
    private let apiKey: String = APIConfig.dashScopeAPIKey
    private let baseURL = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime"
    private let model = APIConfig.asrModel

    // 音频配置
    private let sampleRate: Double = 16000
    private let audioFormat = "pcm"

    // 用户录音数据缓冲（用于保存用户语音，可重播）
    private var recordedAudioData = Data()

    // 回调
    var onTextReceived: ((String, Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?

    // 连接完成的 continuation
    private var connectionContinuation: CheckedContinuation<Void, Error>?

    private override init() {
        super.init()
    }

    deinit {
        if let cont = connectionContinuation {
            cont.resume(throwing: ASRError.notConnected)
        }
        disconnect()
    }

    // MARK: - Connection Management

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
            throw ASRError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.timeoutInterval = 30

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.delegate = self

        webSocketTask?.resume()

        // 等待连接建立（使用 continuation 等待委托回调）
        try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
            // 设置超时
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                if let cont = self?.connectionContinuation {
                    self?.connectionContinuation = nil
                    cont.resume(throwing: ASRError.connectionTimeout)
                }
            }
        }

        isConnecting = false
        isReady = true

        // 发送 session.update 配置会话
        try await sendSessionUpdate()
    }

    /// 预连接 WebSocket（在进入页面时调用）
    /// 返回是否连接成功
    @discardableResult
    func prepare() async -> Bool {
        print("[AliyunASR] prepare() 被调用，isReady: \(isReady), isConnecting: \(isConnecting)")
        guard !isReady && !isConnecting else {
            print("[AliyunASR] 跳过预连接，当前状态 - isReady: \(isReady), isConnecting: \(isConnecting)")
            return isReady
        }

        do {
            print("[AliyunASR] 预连接 WebSocket...")
            try await connect()
            print("[AliyunASR] 预连接成功")
            return true
        } catch {
            print("[AliyunASR] 预连接失败: \(error.localizedDescription)")
            isReady = false
            isConnecting = false
            return false
        }
    }

    /// 断开 WebSocket 连接
    func disconnect() {
        // 清理 continuation
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: ASRError.notConnected)
        }

        // 停止录音
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        // 发送 session.finish
        sendSessionFinish()

        // 先清理引用，再关闭连接
        let taskToClose = webSocketTask
        webSocketTask = nil

        taskToClose?.cancel(with: .normalClosure, reason: nil)

        isRecording = false
        isConnecting = false
        isReady = false
        onConnectionStatusChanged?(false)
    }

    /// 重置连接状态（用于录音完成后保持连接）
    func resetRecordingState() {
        isRecording = false
        transcript = ""
        isSessionCancelled = false
        hasValidAudio = false
        validAudioFrameCount = 0
        recordedAudioData = Data()  // 清空录音数据
    }

    /// 检查是否检测到有效音频
    func hasDetectedValidAudio() -> Bool {
        guard hasValidAudio else { return false }

        // 过滤已知的噪音幻觉短语
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if hallucinationPhrases.contains(trimmed) {
            print("[AliyunASR] 过滤噪音幻觉: '\(transcript)'")
            return false
        }

        return true
    }

    /// 获取录音数据（WAV 格式，可用于播放）
    func getRecordedAudioData() -> Data? {
        guard !recordedAudioData.isEmpty else { return nil }
        return createWavDataFromPCM(recordedAudioData)
    }

    /// 将 PCM 数据转换为 WAV 格式
    private func createWavDataFromPCM(_ pcmData: Data) -> Data {
        var wavData = Data()

        let sampleRateValue: UInt32 = UInt32(sampleRate)
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate: UInt32 = sampleRateValue * UInt32(channels) * UInt32(bitsPerSample) / 8
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
        wavData.append(contentsOf: withUnsafeBytes(of: sampleRateValue.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data chunk
        wavData.append(contentsOf: "data".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        wavData.append(pcmData)

        return wavData
    }

    // MARK: - Audio Recording

    /// 开始录音并实时发送音频数据
    func startRecording(language: String = "en") throws {
        guard !isRecording else {
            print("[AliyunASR] 已经在录音中")
            return
        }

        // 重置取消标志，开始新的会话
        isSessionCancelled = false

        // 重置音量检测状态
        hasValidAudio = false
        validAudioFrameCount = 0

        // 清空录音数据缓冲区
        recordedAudioData = Data()

        // 清除之前的识别结果
        transcript = ""

        // 确保 WebSocket 已连接
        guard webSocketTask?.state == .running else {
            throw ASRError.notConnected
        }

        // 配置音频会话（使用 playAndRecord 模式，与 TTS 相同）
        let audioSession = AVAudioSession.sharedInstance()

        // 音频会话应该已经由 TTS 或之前配置为 playAndRecord
        // 确保 audio session 是活跃的
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        print("[AliyunASR] 音频会话已激活")

        // 创建新的音频引擎
        let engine = AVAudioEngine()
        audioEngine = engine

        // 配置音频引擎
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        // 获取输入节点的原生格式
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("[AliyunASR] 输入节点格式: \(inputFormat)")

        // 安装音频 tap - 使用输入节点的原生格式，然后在 processAudioBuffer 中转换
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        engine.prepare()
        try engine.start()

        isRecording = true
        transcript = ""

        print("[AliyunASR] 开始录音，语言: \(language)")
    }

    /// 停止录音
    func stopRecording() -> String {
        let finalTranscript = transcript

        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        // 发送 commit 触发最终的识别结果
        sendInputBufferCommit()

        isRecording = false

        print("[AliyunASR] 停止录音，最终转录: \(finalTranscript)")
        return finalTranscript
    }

    /// 取消录音（不返回结果）
    func cancelRecording() {
        print("[AliyunASR] cancelRecording 被调用")

        // 标记会话已取消，忽略后续异步消息
        isSessionCancelled = true

        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        // 立即清除本地状态
        isRecording = false
        transcript = ""

        // 阿里云 ASR 不支持 input_audio_buffer.clear，需要断开连接来清除服务器端状态
        disconnect()
        print("[AliyunASR] 已断开连接以清除服务器端状态")
    }

    // MARK: - WebSocket Message Handlers

    /// 发送 session.update 配置会话
    private func sendSessionUpdate() async throws {
        // 参考 Python 示例的简单配置（非 VAD 模式）
        let sessionConfig: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text"],
                "input_audio_format": "pcm",
                "sample_rate": Int(sampleRate),
                "input_audio_transcription": [
                    "language": "en"  // 英语优先（模型本身支持多语言，中文也可识别）
                ],
                "turn_detection": NSNull()  // 手动模式，不由服务器 VAD 控制
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: sessionConfig)
        guard let jsonString = jsonData.string else {
            throw ASRError.encodingFailed
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        try await webSocketTask?.send(message)
        print("[AliyunASR] 发送 session.update: \(jsonString)")
    }

    /// 发送音频数据
    private func sendAudioData(_ base64Data: String) {
        let event: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Data
        ]

        guard let jsonString = try? JSONSerialization.data(withJSONObject: event).string else {
            print("[AliyunASR] 错误: 无法序列化音频数据")
            return
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[AliyunASR] 发送音频数据失败: \(error)")
            }
        }
    }

    /// 发送 commit 请求（手动触发识别）
    private func sendInputBufferCommit() {
        let event: [String: Any] = [
            "type": "input_audio_buffer.commit"
        ]

        guard let jsonString = try? JSONSerialization.data(withJSONObject: event).string else { return }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[AliyunASR] 发送 commit 失败: \(error)")
            } else {
                print("[AliyunASR] 发送 commit")
            }
        }
    }

    /// 发送 clear 请求（清除音频缓冲区，取消当前识别）
    private func sendInputBufferClear() {
        let event: [String: Any] = [
            "type": "input_audio_buffer.clear"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("[AliyunASR] clear 消息序列化失败")
            return
        }

        print("[AliyunASR] 发送 clear 消息: \(jsonString)")

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[AliyunASR] 发送 clear 失败: \(error)")
            } else {
                print("[AliyunASR] 发送 clear 成功")
            }
        }
    }

    /// 发送 session.finish 结束会话
    private func sendSessionFinish() {
        let event: [String: Any] = [
            "type": "session.finish"
        ]

        guard let jsonString = try? JSONSerialization.data(withJSONObject: event).string else { return }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if error == nil {
                print("[AliyunASR] 发送 session.finish")
            }
        }
    }

    // MARK: - Audio Processing

    /// 处理音频缓冲区并发送
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard buffer.frameLength > 0 else { return }

        // 检测音量（RMS）
        if let floatChannelData = buffer.floatChannelData {
            let frameLength = Int(buffer.frameLength)
            var rms: Float = 0
            for i in 0..<frameLength {
                let sample = floatChannelData[0][i]
                rms += sample * sample
            }
            rms = sqrt(rms / Float(frameLength))

            // 需要多帧持续超过阈值才标记为有效（过滤瞬时噪音）
            if rms > volumeThreshold {
                validAudioFrameCount += 1
                if validAudioFrameCount >= minValidFrameCount {
                    hasValidAudio = true
                }
            }
        }

        // 重采样到 16000Hz, Int16
        guard let resampledData = resampleBuffer(buffer, targetSampleRate: sampleRate) else {
            return
        }

        // 保存录音数据到本地缓冲区
        recordedAudioData.append(resampledData)

        // 发送到服务器进行识别
        sendAudioData(resampledData.base64EncodedString())
    }

    /// 重采样音频缓冲区到目标格式
    private func resampleBuffer(_ buffer: AVAudioPCMBuffer, targetSampleRate: Double) -> Data? {
        let sourceFormat = buffer.format
        let sourceSampleRate = sourceFormat.sampleRate

        // 如果格式已经是目标格式，直接转换
        if sourceSampleRate == targetSampleRate && sourceFormat.commonFormat == .pcmFormatInt16 {
            guard let int16Pointer = buffer.int16ChannelData?[0] else { return nil }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return nil }
            // 创建 Data 会自动复制数据，避免悬空指针
            var data = Data(count: frameLength * 2)
            data.withUnsafeMutableBytes { dest in
                guard let destPtr = dest.baseAddress else { return }
                memcpy(destPtr, int16Pointer, frameLength * 2)
            }
            return data
        }

        // 创建目标格式
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: true
        ) else {
            return nil
        }

        // 创建转换器
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            return nil
        }

        // 计算输出帧数
        let ratio = targetSampleRate / sourceSampleRate
        let targetFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 10

        // 创建输出缓冲区
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: targetFrames) else {
            return nil
        }

        // 执行转换
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            print("[AliyunASR] 重采样错误: \(error)")
            return nil
        }

        // 提取 Int16 数据
        guard let int16Pointer = outputBuffer.int16ChannelData?[0] else { return nil }
        let frameLength = Int(outputBuffer.frameLength)
        guard frameLength > 0 else { return nil }
        // 创建 Data 会自动复制数据，避免悬空指针
        var data = Data(count: frameLength * 2)
        data.withUnsafeMutableBytes { dest in
            guard let destPtr = dest.baseAddress else { return }
            memcpy(destPtr, int16Pointer, frameLength * 2)
        }
        return data
    }

    /// 开始接收消息
    private func startReceiving() {
        print("[AliyunASR] 开始接收消息循环")
        // 检查当前任务的引用，避免在旧任务上接收
        let currentTask = webSocketTask
        currentTask?.receive { [weak self] result in
            guard let self = self else { return }

            // 确保我们还在处理同一个任务
            guard self.webSocketTask === currentTask else {
                print("[AliyunASR] 忽略旧任务的接收回调")
                return
            }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // 继续接收下一条消息
                self.startReceiving()

            case .failure(let error):
                print("[AliyunASR] WebSocket 接收错误: \(error)")
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
            print("[AliyunASR] 未知消息类型")
            return
        }

        guard let data = messageData,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[AliyunASR] 无法解析消息")
            return
        }

        // 处理不同类型的服务器事件
        if let type = json["type"] as? String {
            // 只记录重要的非频繁事件
            switch type {
            case "session.created":
                print("[AliyunASR] 会话创建成功")

            case "session.updated":
                print("[AliyunASR] 会话更新成功")

            case "input_audio_buffer.committed":
                print("[AliyunASR] 音频缓冲区已提交")

            case "input_audio_transcription.delta":
                // 增量转录结果（实时部分识别）
                // 如果会话已取消，忽略该消息
                guard !self.isSessionCancelled else {
                    print("[AliyunASR] 会话已取消，忽略 delta 消息")
                    return
                }
                if let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    DispatchQueue.main.async {
                        guard !self.isSessionCancelled else { return }
                        self.transcript = self.transcript + text
                        self.onTextReceived?(self.transcript, false)
                    }
                }

            case "input_audio_transcription.completed":
                // 转录完成 - 最终完整结果
                // 如果会话已取消，忽略该消息
                guard !self.isSessionCancelled else {
                    print("[AliyunASR] 会话已取消，忽略 completed 消息")
                    return
                }
                if let transcript = json["transcript"] as? String {
                    DispatchQueue.main.async {
                        guard !self.isSessionCancelled else { return }
                        self.transcript = transcript
                        self.onTextReceived?(transcript, true)
                    }
                }

            case "conversation.item.input_audio_transcription.text":
                // 阿里云ASR实时增量结果 - 从 stash 字段获取
                // 如果会话已取消，忽略该消息
                guard !self.isSessionCancelled else {
                    print("[AliyunASR] 会话已取消，忽略 text 消息")
                    return
                }
                if let stash = json["stash"] as? String, !stash.isEmpty {
                    DispatchQueue.main.async {
                        guard !self.isSessionCancelled else { return }
                        self.transcript = stash
                        self.onTextReceived?(stash, false)
                        print("[AliyunASR] 实时转录: \(stash)")
                    }
                }

            case "conversation.item.input_audio_transcription.completed":
                // 阿里云ASR最终识别结果 - 从 transcript 字段获取
                // 如果会话已取消，忽略该消息
                guard !self.isSessionCancelled else {
                    print("[AliyunASR] 会话已取消，忽略 completed 消息")
                    return
                }
                if let transcript = json["transcript"] as? String, !transcript.isEmpty {
                    DispatchQueue.main.async {
                        guard !self.isSessionCancelled else { return }
                        self.transcript = transcript
                        self.onTextReceived?(transcript, true)
                        print("[AliyunASR] 最终转录完成: \(transcript)")
                    }
                }

            case "session.finished":
                // 会话结束
                print("[AliyunASR] 会话结束")
                if let transcript = json["transcript"] as? String {
                    DispatchQueue.main.async {
                        self.transcript = transcript
                        self.onTextReceived?(transcript, true)
                    }
                }

            case "error":
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("[AliyunASR] 服务器错误: \(message)")
                    DispatchQueue.main.async {
                        self.errorMessage = message
                    }
                }

            default:
                print("[AliyunASR] 收到事件: \(type)")
            }
        }
    }

    // MARK: - Helper Methods
}

// MARK: - URLSessionWebSocketDelegate
extension AliyunASRService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // 只处理当前任务的回调
        guard webSocketTask === self.webSocketTask else {
            print("[AliyunASR] 忽略旧任务的连接打开回调")
            return
        }
        print("[AliyunASR] WebSocket 连接已打开")

        // 恢复等待连接的 continuation
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume()
        }

        DispatchQueue.main.async {
            self.onConnectionStatusChanged?(true)
        }

        // 开始接收消息
        startReceiving()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // 只处理当前任务的回调
        guard webSocketTask === self.webSocketTask else {
            print("[AliyunASR] 忽略旧任务的连接关闭回调")
            return
        }
        print("[AliyunASR] WebSocket 连接已关闭: \(closeCode)")

        // 如果有等待的 continuation，恢复它并抛出错误
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: ASRError.notConnected)
        }

        DispatchQueue.main.async {
            self.isRecording = false
            self.isConnecting = false
            self.isReady = false
            self.onConnectionStatusChanged?(false)
        }

        // 非正常关闭时，尝试自动重连
        if closeCode != .normalClosure {
            print("[AliyunASR] 连接异常关闭，3秒后尝试重连...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                Task {
                    try? await self.connect()
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 只处理当前任务的回调
        guard task === self.webSocketTask else {
            print("[AliyunASR] 忽略旧任务的任务完成回调")
            return
        }
        if let error = error {
            print("[AliyunASR] WebSocket 任务错误: \(error)")

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

// MARK: - Data Extension
extension Data {
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}

// MARK: - ASRError
enum ASRError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case connectionTimeout
    case audioSessionFailed
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
        case .audioSessionFailed:
            return "音频会话配置失败"
        case .encodingFailed:
            return "音频编码失败"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}
