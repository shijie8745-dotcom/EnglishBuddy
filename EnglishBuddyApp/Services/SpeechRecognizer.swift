import Foundation
import Combine
import AVFAudio

/// 语音识别器 - 使用阿里云 qwen3-asr-flash-realtime 服务
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false

    private let asrService = AliyunASRService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 设置 ASR 回调
        setupCallbacks()
    }

    private func setupCallbacks() {
        asrService.onTextReceived = { [weak self] text, _ in
            DispatchQueue.main.async {
                self?.transcript = text
            }
        }

        asrService.onError = { [weak self] error in
            DispatchQueue.main.async {
                print("[SpeechRecognizer] ASR 错误: \(error.localizedDescription)")
            }
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

        // 立即设置状态
        DispatchQueue.main.async {
            self.isRecording = true
            self.transcript = ""
            print("[SpeechRecognizer] isRecording 设置为 true")
        }

        // 异步执行连接和录音
        Task {
            do {
                print("[SpeechRecognizer] 开始连接 WebSocket...")
                // 连接 WebSocket
                try await asrService.connect()
                print("[SpeechRecognizer] WebSocket 连接成功")
                // 开始录音
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

        // 延迟断开连接，确保最后的识别结果返回
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.asrService.disconnect()
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

            // 断开连接
            self.asrService.disconnect()

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
