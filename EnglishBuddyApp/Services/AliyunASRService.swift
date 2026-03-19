import Foundation
import AVFAudio
import Combine

/// 阿里云实时语音识别服务 (qwen3-asr-flash-realtime-2026-02-10)
/// 使用 WebSocket API 进行实时语音转文字
final class AliyunASRService: NSObject, ObservableObject {
    static let shared = AliyunASRService()

    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isConnecting = false
    @Published var errorMessage: String?

    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?

    // MARK: - Configuration
    private let apiKey: String = APIConfig.dashScopeAPIKey
    private let websocketURL = "wss://dashscope.aliyuncs.com/api/v1/services/realtime/stt/streaming"
    private let model = "qwen3-asr-flash-realtime-2026-02-10"

    // 音频配置
    private let sampleRate: Double = 16000
    private let audioFormat = "pcm"

    // 回调
    var onTextReceived: ((String, Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    /// 连接到 WebSocket 服务
    func connect() async throws {
        guard webSocketTask == nil || webSocketTask?.state != .running else {
            print("[AliyunASR] WebSocket 已连接")
            return
        }

        isConnecting = true
        errorMessage = nil

        guard let url = URL(string: websocketURL) else {
            throw ASRError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 30

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.delegate = self

        webSocketTask?.resume()

        // 等待连接建立
        try await waitForConnection()

        isConnecting = false

        // 发送 session.update 配置会话
        try await sendSessionUpdate()
    }

    /// 断开 WebSocket 连接
    func disconnect() {
        // 停止录音
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        // 发送 session.finish
        sendSessionFinish()

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        isRecording = false
        isConnecting = false
        onConnectionStatusChanged?(false)
    }

    // MARK: - Audio Recording

    /// 开始录音并实时发送音频数据
    func startRecording(language: String = "en") throws {
        guard !isRecording else {
            print("[AliyunASR] 已经在录音中")
            return
        }

        // 确保 WebSocket 已连接
        guard webSocketTask?.state == .running else {
            throw ASRError.notConnected
        }

        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 创建新的音频引擎
        let engine = AVAudioEngine()
        audioEngine = engine

        // 配置音频引擎
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        // 创建转换格式 (16000Hz, 单声道, PCM)
        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: true
        ) else {
            throw ASRError.audioSessionFailed
        }

        // 安装音频 tap
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
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
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        isRecording = false
        transcript = ""
    }

    // MARK: - WebSocket Message Handlers

    /// 发送 session.update 配置会话
    private func sendSessionUpdate() async throws {
        let sessionConfig: [String: Any] = [
            "event_id": "session_\(UUID().uuidString)",
            "type": "session.update",
            "session": [
                "input_audio_format": [
                    "type": audioFormat,
                    "sample_rate": Int(sampleRate)
                ],
                "language": "en",  // 英语识别
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 800
                ],
                "model": model
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: sessionConfig)
        let message = URLSessionWebSocketTask.Message.data(jsonData)

        try await webSocketTask?.send(message)
        print("[AliyunASR] 发送 session.update")
    }

    /// 发送音频数据
    private func sendAudioData(_ base64Data: String) {
        let event: [String: Any] = [
            "event_id": "audio_\(UUID().uuidString)",
            "type": "input_audio_buffer.append",
            "audio": base64Data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: event) else {
            print("[AliyunASR] 错误: 无法序列化音频数据")
            return
        }

        let message = URLSessionWebSocketTask.Message.data(jsonData)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[AliyunASR] 发送音频数据失败: \(error)")
            }
        }
    }

    /// 发送 commit 请求（手动触发识别）
    private func sendInputBufferCommit() {
        let event: [String: Any] = [
            "event_id": "commit_\(UUID().uuidString)",
            "type": "input_audio_buffer.commit"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: event) else { return }

        let message = URLSessionWebSocketTask.Message.data(jsonData)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[AliyunASR] 发送 commit 失败: \(error)")
            } else {
                print("[AliyunASR] 发送 commit")
            }
        }
    }

    /// 发送 session.finish 结束会话
    private func sendSessionFinish() {
        let event: [String: Any] = [
            "event_id": "finish_\(UUID().uuidString)",
            "type": "session.finish"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: event) else { return }

        let message = URLSessionWebSocketTask.Message.data(jsonData)
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

        // 将音频数据转换为 Base64
        if let int16Data = buffer.int16ChannelData?[0] {
            let frameLength = Int(buffer.frameLength)
            var data = Data()
            data.reserveCapacity(frameLength * 2)

            for i in 0..<frameLength {
                var sample = int16Data[i]
                data.append(UnsafeBufferPointer(start: &sample, count: 1))
            }

            sendAudioData(data.base64EncodedString())
        }
    }

    /// 开始接收消息
    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

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
            switch type {
            case "session.created":
                print("[AliyunASR] 会话创建成功")

            case "session.updated":
                print("[AliyunASR] 会话更新成功")

            case "input_audio_buffer.committed":
                print("[AliyunASR] 音频缓冲区已提交")

            case "conversation.item.input_audio_transcription.completed":
                // 转录完成 - 最终完整结果
                if let item = json["item"] as? [String: Any],
                   let transcript = item["transcript"] as? String {
                    DispatchQueue.main.async {
                        self.transcript = transcript
                        self.onTextReceived?(transcript, true)
                    }
                }

            case "conversation.item.input_audio_transcription.delta":
                // 增量转录结果（实时部分识别）
                if let item = json["item"] as? [String: Any],
                   let transcript = item["transcript"] as? String {
                    DispatchQueue.main.async {
                        self.transcript = transcript
                        self.onTextReceived?(transcript, false)
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

    /// 等待 WebSocket 连接建立
    private func waitForConnection() async throws {
        var attempts = 0
        while webSocketTask?.state != .running && attempts < 30 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            attempts += 1
        }

        guard webSocketTask?.state == .running else {
            throw ASRError.connectionTimeout
        }

        // 开始接收消息
        startReceiving()
    }
}

// MARK: - URLSessionWebSocketDelegate
extension AliyunASRService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[AliyunASR] WebSocket 连接已打开")
        DispatchQueue.main.async {
            self.onConnectionStatusChanged?(true)
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[AliyunASR] WebSocket 连接已关闭: \(closeCode)")
        DispatchQueue.main.async {
            self.isRecording = false
            self.isConnecting = false
            self.onConnectionStatusChanged?(false)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("[AliyunASR] WebSocket 任务错误: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.onError?(error)
            }
        }
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
