import Foundation
import Observation
import AVFoundation

@Observable
class TTSService: NSObject {
    static let shared = TTSService()
    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    var isSpeaking = false

    /// 当前播放的消息ID
    var currentPlayingMessageId: UUID?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    private let apiKey = APIConfig.dashScopeAPIKey
    private let ttsURL = APIConfig.dashScopeTTSURL
    private let model = APIConfig.ttsModel
    private let voice = APIConfig.ttsVoice
    private let instructions = APIConfig.ttsInstructions

    /// 播放指定文本的语音（同步版本，用于兼容旧代码）
    /// - forceSystemTTS: 强制使用系统TTS（用于ChatTestView）
    func speak(_ text: String, speed: Float? = nil, forceSystemTTS: Bool = false) {
        Task {
            _ = await speak(text, for: nil, speed: speed, forceSystemTTS: forceSystemTTS)
        }
    }

    /// 播放指定文本的语音，并返回音频数据
    /// - forceSystemTTS: 强制使用系统TTS（用于ChatTestView）
    func speak(_ text: String, for messageId: UUID?, speed: Float? = nil, forceSystemTTS: Bool = false) async -> Data? {
        let filteredText = text.filteringForTTS
        print("[TTSService] TTS文本: \(filteredText)")

        return await speakWithBuffer(text: filteredText, messageId: messageId, speed: speed, forceSystemTTS: forceSystemTTS)
    }

    /// 从缓存数据播放（用于重复播放）
    func playFromCache(_ audioData: Data, for messageId: UUID) {
        stop()

        currentPlayingMessageId = messageId
        isSpeaking = true

        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // 设置播放完成回调
            audioPlayer?.play()
            print("[TTSService] 从缓存播放，消息ID: \(messageId)")

        } catch {
            print("[TTSService] 缓存播放错误: \(error)")
            isSpeaking = false
            currentPlayingMessageId = nil
        }
    }

    /// 使用缓冲策略获取音频数据并播放
    /// - forceSystemTTS: 强制使用系统TTS（用于ChatTestView）
    private func speakWithBuffer(text: String, messageId: UUID?, speed: Float?, forceSystemTTS: Bool = false) async -> Data? {
        guard !text.isEmpty else { return nil }

        // 如果强制使用系统TTS（如ChatTestView），直接回退
        if forceSystemTTS {
            print("[TTSService] 强制使用系统 TTS")
            fallbackToSystemTTS(text: text, messageId: messageId, speed: speed)
            return nil
        }

        // 步骤1: 获取音频 URL
        guard let audioURL = await fetchAudioURL(text: text) else {
            print("[TTSService] 获取音频URL失败，使用系统TTS")
            fallbackToSystemTTS(text: text, messageId: messageId, speed: speed)
            return nil
        }

        // 步骤2: 下载音频数据
        guard let audioData = await downloadAudioData(from: audioURL) else {
            print("[TTSService] 下载音频失败，使用系统TTS")
            fallbackToSystemTTS(text: text, messageId: messageId, speed: speed)
            return nil
        }

        // 步骤3: 播放音频
        await playAudioData(audioData, messageId: messageId)

        return audioData
    }

    /// 获取音频 URL
    private func fetchAudioURL(text: String) async -> URL? {
        let requestBody: [String: Any] = [
            "model": model,
            "input": [
                "text": text,
                "voice": voice,
                "language_type": "English"
            ],
            "instructions": instructions,
            "optimize_instructions": true,
            "stream": false
        ]

        guard let url = URL(string: ttsURL),
              let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        do {
            print("[TTSService] 请求音频URL...")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[TTSService] HTTP状态码错误: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("[TTSService] 错误响应: \(errorStr)")
                }
                return nil
            }

            // 打印完整响应用于调试
            if let responseString = String(data: data, encoding: .utf8) {
                print("[TTSService] 完整响应: \(responseString)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("[TTSService] JSON解析失败")
                return nil
            }

            // 根据官方示例，尝试解析响应
            // output.audio.url 或直接的 audio.url
            var urlString: String? = nil

            if let output = json["output"] as? [String: Any] {
                print("[TTSService] 找到output字段: \(output.keys)")
                if let audio = output["audio"] as? [String: Any] {
                    print("[TTSService] 找到audio字段: \(audio.keys)")
                    urlString = audio["url"] as? String
                }
                // 有的可能是直接在output里的url
                if urlString == nil {
                    urlString = output["url"] as? String
                }
            }

            // 尝试audio字段直接在根层级
            if urlString == nil, let audio = json["audio"] as? [String: Any] {
                print("[TTSService] 在根层级找到audio字段: \(audio.keys)")
                urlString = audio["url"] as? String
            }

            guard var urlString = urlString else {
                print("[TTSService] 无法获取音频URL")
                return nil
            }

            // 转换为 HTTPS
            if urlString.hasPrefix("http://") {
                urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
            }

            print("[TTSService] 获取到音频URL")
            return URL(string: urlString)

        } catch {
            print("[TTSService] 请求错误: \(error)")
            return nil
        }
    }

    /// 下载完整音频数据
    private func downloadAudioData(from url: URL) async -> Data? {
        do {
            print("[TTSService] 开始下载音频...")
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("[TTSService] 下载失败: 状态码错误")
                return nil
            }

            print("[TTSService] 下载完成: \(data.count) bytes")
            return data

        } catch {
            print("[TTSService] 下载错误: \(error)")
            return nil
        }
    }

    /// 播放音频数据
    private func playAudioData(_ data: Data, messageId: UUID?) async {
        stop()

        currentPlayingMessageId = messageId
        isSpeaking = true

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("[TTSService] 开始播放")

            // 等待播放完成
            while audioPlayer?.isPlaying == true {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            print("[TTSService] 播放完成")

        } catch {
            print("[TTSService] 播放错误: \(error)")
        }

        isSpeaking = false
        currentPlayingMessageId = nil
    }

    private func fallbackToSystemTTS(text: String, messageId: UUID?, speed: Float?) {
        print("[TTSService] 使用系统TTS")

        // 设置播放状态
        currentPlayingMessageId = messageId
        isSpeaking = true

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        let userSpeed = speed ?? DataStore.loadUser().aiVoiceSpeed
        let mappedRate = 0.3 + (userSpeed - 0.5) * 0.4
        utterance.rate = Float(mappedRate)

        // 设置 utterance 的标识以便在代理回调中识别
        if let messageId = messageId {
            utterance.pitchMultiplier = Float(messageId.uuidString.hashValue) / Float(Int.max) + 0.5
        }

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        isSpeaking = false
        currentPlayingMessageId = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("[TTSService] 系统TTS播放结束")
        isSpeaking = false
        currentPlayingMessageId = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("[TTSService] 系统TTS播放取消")
        isSpeaking = false
        currentPlayingMessageId = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension TTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("[TTSService] 播放结束，成功: \(flag)")
        isSpeaking = false
        currentPlayingMessageId = nil
    }
}

// MARK: - String Extension

extension String {
    var filteringForTTS: String {
        return self.filter { char in
            let scalar = char.unicodeScalars.first!
            let value = scalar.value

            if (value >= 0x41 && value <= 0x5A) || (value >= 0x61 && value <= 0x7A) {
                return true
            }
            if value >= 0x4E00 && value <= 0x9FFF {
                return true
            }
            if value >= 0x30 && value <= 0x39 {
                return true
            }
            if [0x20, 0x2C, 0x2E, 0x21, 0x3F, 0x27, 0x2D].contains(value) {
                return true
            }
            return false
        }
    }
}
