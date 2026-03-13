import Foundation
import Observation
import Combine

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var isRecording = false
    var recognizedText = ""
    var inputText = ""
    var errorMessage: String?
    var currentLesson: Lesson?

    /// 当前正在播放的消息ID
    var currentlyPlayingMessageId: UUID?

    private var speechRecognizer: SpeechRecognizer?
    private var cancellables = Set<AnyCancellable>()
    private var ttsObservation: AnyCancellable?

    init() {
        // 监听 TTS 播放状态变化
        ttsObservation = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePlayingState()
            }
    }

    private func updatePlayingState() {
        let tts = TTSService.shared
        let newPlayingId = tts.isSpeaking ? tts.currentPlayingMessageId : nil

        // 如果播放状态变化，更新消息状态
        if currentlyPlayingMessageId != newPlayingId {
            // 清除之前的播放状态
            if let oldId = currentlyPlayingMessageId,
               let index = messages.firstIndex(where: { $0.id == oldId }) {
                messages[index].isPlaying = false
            }

            // 设置新的播放状态
            if let newId = newPlayingId,
               let index = messages.firstIndex(where: { $0.id == newId }) {
                messages[index].isPlaying = true
            }

            currentlyPlayingMessageId = newPlayingId
        }
    }

    /// 点击消息播放/停止
    func togglePlay(for message: ChatMessage) {
        // 排除错误消息
        guard !message.isError else { return }

        // 如果正在播放这条消息，则停止
        if currentlyPlayingMessageId == message.id {
            TTSService.shared.stop()
            return
        }

        // 停止当前播放
        TTSService.shared.stop()

        // 清除所有播放状态
        for index in messages.indices {
            messages[index].isPlaying = false
        }
        currentlyPlayingMessageId = nil

        // 用户消息：播放用户录音（如果有）
        if message.speaker == .user {
            if let voiceData = message.userVoiceData {
                print("[ChatViewModel] 播放用户录音")
                TTSService.shared.playFromCache(voiceData, for: message.id)
            } else {
                print("[ChatViewModel] 用户消息没有录音数据")
            }
            return
        }

        // AI 消息：使用 TTS
        // 如果有缓存的音频数据，直接播放
        if let audioData = message.audioData {
            print("[ChatViewModel] 使用缓存TTS播放")
            TTSService.shared.playFromCache(audioData, for: message.id)
        } else {
            // 否则重新生成 TTS
            print("[ChatViewModel] 重新生成 TTS")
            let ttsText = message.text.removingEmoji
            Task {
                if let audioData = await TTSService.shared.speak(ttsText, for: message.id) {
                    // 保存音频数据到消息
                    if let index = messages.firstIndex(where: { $0.id == message.id }) {
                        messages[index].audioData = audioData
                    }
                }
            }
        }
    }

    /// 清理所有音频数据（在退出会话时调用）
    func clearAudioCache() {
        for index in messages.indices {
            messages[index].audioData = nil
            messages[index].userVoiceData = nil
            messages[index].isPlaying = false
        }
        currentlyPlayingMessageId = nil
        TTSService.shared.stop()
    }

    func loadInitialMessages(for lesson: Lesson) {
        currentLesson = lesson
        messages = []
        currentlyPlayingMessageId = nil

        // Start with an AI greeting using the model
        Task {
            await generateAIResponse(to: "Hello! I'm ready to learn \(lesson.title).")
        }
    }

    private func addAIMessage(_ text: String) async {
        // Strip emojis for TTS but keep them in the displayed message
        let ttsText = text.removingEmoji
        print("添加到消息的文本: \(text)")
        print("TTS文本: \(ttsText)")

        let message = ChatMessage(text: text, speaker: .ai)
        messages.append(message)

        // 生成 TTS 并保存音频数据
        if let audioData = await TTSService.shared.speak(ttsText, for: message.id) {
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].audioData = audioData
            }
        }
    }


    func sendMessage(_ text: String, voiceData: Data? = nil) async {
        guard !text.isEmpty else { return }

        // Add user message（同时保存录音数据）
        messages.append(ChatMessage(text: text, speaker: .user, userVoiceData: voiceData))

        // Use AI to respond
        await generateAIResponse(to: text)
    }

    private func generateAIResponse(to text: String) async {
        isLoading = true

        do {
            let response = try await AIChatService.shared.sendMessage(text, lessonId: currentLesson?.id ?? 0)
            print("=== AI原始响应 ===")
            print(response)
            print("==================")
            // 消息添加到界面后立即关闭 loading，让 TTS 在后台播放
            isLoading = false
            await addAIMessage(response)
        } catch {
            // Fallback to encouraging responses if AI service fails
            let fallbackResponses = [
                "Wonderful! You're speaking great English!",
                "Excellent! I can understand you perfectly!",
                "Great job! Keep practicing! You're doing amazing!",
                "Fantastic! You're learning so fast! I'm proud of you!",
                "Super! That was really good English! Keep going!"
            ]
            let randomResponse = fallbackResponses.randomElement() ?? fallbackResponses[0]
            // 消息添加到界面后立即关闭 loading，让 TTS 在后台播放
            isLoading = false
            await addAIMessage(randomResponse)
        }
    }

    // MARK: - Voice Recording

    func requestSpeechAuthorization() {
        let recognizer = SpeechRecognizer()
        recognizer.requestAuthorization { [weak self] granted in
            guard let self = self else { return }
            if !granted {
                self.errorMessage = "需要麦克风权限才能使用语音功能"
            }
        }
    }

    func startRecording() {
        // Initialize speech recognizer
        speechRecognizer = SpeechRecognizer()

        // Set up observation of transcript changes
        speechRecognizer?.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newText in
                self?.recognizedText = newText
            }
            .store(in: &cancellables)

        speechRecognizer?.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recording in
                self?.isRecording = recording
            }
            .store(in: &cancellables)

        recognizedText = ""
        isRecording = true

        do {
            try speechRecognizer?.startRecording()
        } catch {
            errorMessage = "无法开始录音，请检查麦克风权限"
            isRecording = false
            speechRecognizer = nil
        }
    }

    /// 临时存储录音数据
    private var pendingVoiceData: Data?

    func stopRecording() {
        // 获取录音数据
        pendingVoiceData = speechRecognizer?.getRecordedAudioData()

        let finalText = speechRecognizer?.stopRecording() ?? ""
        isRecording = false
        recognizedText = ""

        // Clean up
        cancellables.removeAll()
        speechRecognizer = nil

        // Validate the recognized text
        let trimmedText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if speech is too short or contains mostly Chinese (likely recognition failure)
        if trimmedText.count < 2 || isMostlyChinese(trimmedText) {
            // Add AI message asking user to repeat
            messages.append(ChatMessage(text: "[未听清]", speaker: .user))
            Task {
                await addAIMessage("I didn't hear you clearly. Can you say that again? 🎤")
            }
            return
        }

        // Send the recognized text to AI（同时保存录音数据）
        Task {
            await sendMessage(trimmedText, voiceData: pendingVoiceData)
        }

        // 清空临时存储
        pendingVoiceData = nil
    }

    func updateRecognizedText() {
        // Transcript is now updated via Combine publisher
    }

    private func isMostlyChinese(_ text: String) -> Bool {
        let chineseCharacters = text.filter { char in
            let scalar = char.unicodeScalars.first!
            // CJK Unified Ideographs range
            return scalar.value >= 0x4E00 && scalar.value <= 0x9FFF
        }
        // If more than 30% of characters are Chinese, consider it mostly Chinese
        guard !text.isEmpty else { return false }
        return Double(chineseCharacters.count) / Double(text.count) > 0.3
    }
}

// MARK: - String Extension for Emoji Removal
extension String {
    var removingEmoji: String {
        return self.filter { !$0.isEmoji }
    }
}

extension Character {
    var isEmoji: Bool {
        // Check if character is an emoji
        let scalar = self.unicodeScalars.first!
        return scalar.properties.isEmoji && (scalar.value > 0x238C ||
               (scalar.value == 0x00A9 || scalar.value == 0x00AE || scalar.value == 0x2122))
    }
}
