import Foundation
import Combine
import AVFAudio

/// 语音识别器 - 使用阿里云 qwen3-asr-flash-realtime 服务
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isReady = false  // WebSocket 已预连接

    private let asrService = AliyunASRService.shared
    private var cancellables = Set<AnyCancellable>()
    private var statusCancellable: AnyCancellable?

    init() {
        // 设置 ASR 回调
        setupCallbacks()
        setupStatusObserver()
    }

    private func setupCallbacks() {
        asrService.onTextReceived = { [weak self] text, _ in
            DispatchQueue.main.async {
                self?.transcript = text
            }
        }

        asrService.onError = { error in
            DispatchQueue.main.async {
                print("[SpeechRecognizer] ASR 错误: \(error.localizedDescription)")
            }
        }
    }

    private func setupStatusObserver() {
        // 监听 ASR 服务的状态变化
        statusCancellable = asrService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isReady = self?.asrService.isReady ?? false
            }
    }

    /// 预连接 WebSocket（在进入页面时调用）
    func prepare() async {
        await asrService.prepare()
    }

    /// 取消录音（不返回结果）
    func cancelRecording() {
        print("[SpeechRecognizer] cancelRecording 被调用")
        asrService.cancelRecording()
        asrService.resetRecordingState()

        DispatchQueue.main.async {
            self.isRecording = false
            self.transcript = ""
        }
    }

    func requestAuthorization() {
        // 请求麦克风权限
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("[SpeechRecognizer] 麦克风权限: \(granted)")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("[SpeechRecognizer] 麦克风权限: \(granted)")
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // 请求麦克风权限
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    func startRecording() throws {
        print("[SpeechRecognizer] startRecording 被调用")

        // ===== 停止 TTS 播放（用户录音优先级最高）=====
        // 注意：TTS 和 ASR 使用相同的 playAndRecord 模式，不需要切换音频会话
        if QwenTTSRealtimeService.shared.isPlaying || QwenTTSRealtimeService.shared.isReady {
            print("[SpeechRecognizer] 停止 TTS 播放")
            QwenTTSRealtimeService.shared.stop()
        }

        // 短暂等待音频引擎停止（不需要等待音频会话切换）
        Thread.sleep(forTimeInterval: 0.1)

        // 异步执行连接和录音
        Task {
            do {
                // 先检查是否已连接
                if !asrService.isReady {
                    print("[SpeechRecognizer] WebSocket 未预连接，开始连接...")
                    try await asrService.connect()
                }

                // 开始录音前设置状态
                await MainActor.run {
                    self.isRecording = true
                    self.transcript = ""
                    print("[SpeechRecognizer] isRecording 设置为 true")
                }

                // 开始录音（内部会配置音频会话）
                try asrService.startRecording()
                print("[SpeechRecognizer] 录音已开始")
            } catch {
                print("[SpeechRecognizer] 开始录音失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.isRecording = false
                }
            }
        }
    }

    func stopRecording() -> String {
        print("[SpeechRecognizer] stopRecording 被调用")

        let finalText = asrService.stopRecording()

        // 重置录音状态，但保持 WebSocket 连接（预连接策略）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.asrService.resetRecordingState()
        }

        DispatchQueue.main.async {
            self.isRecording = false
            print("[SpeechRecognizer] isRecording 设置为 false")
        }

        return finalText
    }

    func stopRecording(completion: @escaping (String) -> Void) {
        // 延迟结束识别任务，让剩余的音频缓冲被处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else {
                completion("")
                return
            }

            // 获取最终的识别结果
            let finalTranscript = self.asrService.stopRecording()

            // 重置录音状态，但保持 WebSocket 连接（预连接策略）
            self.asrService.resetRecordingState()

            DispatchQueue.main.async {
                self.isRecording = false
            }

            completion(finalTranscript)
        }
    }

    /// 获取录音数据（阿里云 ASR 不保存本地录音，返回 nil）
    func getRecordedAudioData() -> Data? {
        // 阿里云 ASR 不需要本地缓存录音数据
        return nil
    }
}

enum SpeechRecognizerError: Error {
    case notAvailable
    case localeNotAvailable
    case requestCreationFailed
    case audioSessionFailed
}
