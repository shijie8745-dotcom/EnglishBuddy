import Foundation
import Observation
import Combine

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var isRecording = false
    var isInCancelZone = false
    var isPreparing = false  // WebSocket 预连接中
    var recognizedText = ""
    var inputText = ""
    var errorMessage: String?
    var currentLesson: Lesson?

    /// Toast 通知
    var showToast = false
    var toastMessage = ""

    /// 当前正在播放的消息ID
    var currentlyPlayingMessageId: UUID?

    /// 会话开始时间（用于计算对话时长）
    private var sessionStartTime: Date? {
        didSet {
            // 实时保存到 UserDefaults 以便崩溃恢复
            if let startTime = sessionStartTime {
                UserDefaults.standard.set(startTime, forKey: Keys.pendingSessionStartTime)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.pendingSessionStartTime)
            }
        }
    }

    /// 本次会话获得的云朵币
    var sessionEarnedCoins: Int = 0

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let pendingSessionStartTime = "pendingSessionStartTime"
    }

    /// 打卡状态提示
    var checkInMessage: String? = nil

    private var speechRecognizer: SpeechRecognizer?
    private var cancellables = Set<AnyCancellable>()

    /// 防重入标志（togglePlay）
    private var isTogglingPlay = false

    /// 录音开始时间（用于检查录音时长）
    private var recordingStartTime: Date?

    init() {
        // 设置流式 TTS 播放状态回调
        QwenTTSRealtimeService.shared.onPlayingStateChanged = { [weak self] isPlaying in
            self?.handleStreamingTTSStateChange(isPlaying: isPlaying)
        }

        // 设置非流式 TTS 播放状态回调
        TTSService.shared.onPlayingStateChanged = { [weak self] isPlaying, messageId in
            self?.handleNonStreamingTTSStateChange(isPlaying: isPlaying, messageId: messageId)
        }

        // 恢复未保存的学习时长
        recoverPendingStudyTime()
    }

    /// 恢复未保存的学习时长（App 崩溃后自动保存）
    private func recoverPendingStudyTime() {
        guard let pendingStart = UserDefaults.standard.object(forKey: Keys.pendingSessionStartTime) as? Date else {
            print("[ChatViewModel] 没有待恢复的学习时长")
            return
        }

        // 计算未保存的学习时长
        let totalSeconds = Date().timeIntervalSince(pendingStart)
        let fullMinutes = Int(totalSeconds) / 60
        let remainingSeconds = Int(totalSeconds) % 60
        var studyMinutes = fullMinutes
        if remainingSeconds >= 30 {
            studyMinutes += 1
        }

        print("[ChatViewModel] 检测到待恢复时长: \(totalSeconds) 秒 = \(studyMinutes) 分钟")

        if studyMinutes > 0 {
            // 保存到用户数据
            var user = DataStore.loadUser()
            user.totalStudyTime += studyMinutes
            _ = user.cloudCoinSystem.earnCoinsFromStudy(minutes: studyMinutes)
            DataStore.shared.saveUser(user)

            print("[ChatViewModel] 恢复未保存的学习时长: \(studyMinutes) 分钟")
        }

        // 清除待处理数据
        UserDefaults.standard.removeObject(forKey: Keys.pendingSessionStartTime)
    }

    /// 处理流式 TTS 播放状态变化
    private func handleStreamingTTSStateChange(isPlaying: Bool) {
        if isPlaying {
            // 流式播放开始，更新消息状态
            if let streamingId = streamingPlayingMessageId {
                currentlyPlayingMessageId = streamingId
                if let index = messages.firstIndex(where: { $0.id == streamingId }) {
                    messages[index].isPlaying = true
                }
            }
        } else {
            // 流式播放结束 - 清除所有消息的播放状态（确保 UI 同步）
            for index in messages.indices {
                messages[index].isPlaying = false
            }
            currentlyPlayingMessageId = nil
            streamingPlayingMessageId = nil
        }
    }

    /// 处理非流式 TTS 播放状态变化
    private func handleNonStreamingTTSStateChange(isPlaying: Bool, messageId: UUID?) {
        if isPlaying, let id = messageId {
            // 非流式播放开始
            currentlyPlayingMessageId = id
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].isPlaying = true
            }
        } else {
            // 非流式播放结束 - 清除所有消息的播放状态（确保 UI 同步）
            for index in messages.indices {
                messages[index].isPlaying = false
            }
            currentlyPlayingMessageId = nil
        }
    }

    /// 点击消息播放/停止
    func togglePlay(for message: ChatMessage) {
        // 防重入保护
        guard !isTogglingPlay else { return }
        isTogglingPlay = true

        // 排除错误消息
        guard !message.isError else {
            isTogglingPlay = false
            return
        }

        // 如果正在播放这条消息，则停止
        if currentlyPlayingMessageId == message.id {
            TTSService.shared.stop()
            isTogglingPlay = false
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
            // 延迟重置防重入标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isTogglingPlay = false
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
                        // 清理超出限制的音频缓存
                        cleanupAudioCacheIfNeeded()
                    }
                }
            }
        }

        // 延迟重置防重入标志
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isTogglingPlay = false
        }
    }

    /// 清理所有音频数据（在退出会话时调用）
    func clearAudioCache() {
        // 先停止所有播放（包括流式和非流式 TTS）
        stopAllPlayback()

        // 清理音频缓存
        for index in messages.indices {
            messages[index].audioData = nil
            messages[index].userVoiceData = nil
            messages[index].isPlaying = false
        }
    }

    /// 音频缓存最大数量
    private let maxCachedAudioCount = 20

    /// 清理超出限制的音频缓存（保留最近的 N 条）
    private func cleanupAudioCacheIfNeeded() {
        // 获取所有有音频的消息索引（AI 音频或用户录音）
        let messagesWithAudio = messages.enumerated().filter {
            $0.element.audioData != nil || $0.element.userVoiceData != nil
        }
        let count = messagesWithAudio.count

        // 如果超过限制，清理最旧的
        if count >= maxCachedAudioCount {
            let toRemove = count - maxCachedAudioCount + 1
            for i in 0..<toRemove {
                let index = messagesWithAudio[i].offset
                messages[index].audioData = nil
                messages[index].userVoiceData = nil
                print("[ChatViewModel] 清理旧音频缓存，索引: \(index)")
            }
        }
    }

    /// 停止所有播放（用户录音时调用，优先级最高）
    func stopAllPlayback() {
        // 停止流式 TTS 播放
        QwenTTSRealtimeService.shared.stop()

        // 停止非流式 TTS 播放
        TTSService.shared.stop()

        // 清除播放状态和动画
        currentlyPlayingMessageId = nil
        streamingPlayingMessageId = nil

        // 清除所有消息的播放状态
        for index in messages.indices {
            messages[index].isPlaying = false
        }

        print("[ChatViewModel] 已停止所有播放，释放音频会话")
    }

    /// 显示网络错误 Toast 通知
    private func showNetworkErrorToast(_ message: String = "没网络啦，连网后再尝试") {
        toastMessage = message
        showToast = true
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showToast = false
        }
    }

    /// 确保 TTS WebSocket 连接可用（用于按需重连）
    private func ensureTTSConnection() async -> Bool {
        // 检查连接状态
        if QwenTTSRealtimeService.shared.isReady {
            return true
        }

        // 尝试重连
        print("[ChatViewModel] TTS WebSocket 未连接，尝试重连...")
        do {
            try await QwenTTSRealtimeService.shared.connect()
            print("[ChatViewModel] TTS WebSocket 重连成功")
            return true
        } catch {
            print("[ChatViewModel] TTS WebSocket 重连失败: \(error.localizedDescription)")
            return false
        }
    }

    func loadInitialMessages(for lesson: Lesson) {
        currentLesson = lesson
        messages = []
        currentlyPlayingMessageId = nil
        sessionStartTime = Date()
        sessionEarnedCoins = 0
        checkInMessage = nil

        // 显示加载状态
        isLoading = true

        // 预连接 WebSocket 并发送AI问候
        Task {
            // 先预连接
            await prepareRecordingAsync()

            // 再发送AI问候（检查网络）
            let greeting = "Hello! I'm ready to learn \(lesson.title)."
            let ttsConnected = await ensureTTSConnection()
            if ttsConnected {
                await generateAIResponse(to: greeting)
            } else {
                // 断网时显示提示，不发送fallback响应
                // 保持 loading 状态 3 秒，让用户看到发送中状态
                await MainActor.run {
                    showNetworkErrorToast()
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 秒
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    /// 预连接 WebSocket（异步版本，可等待）
    private func prepareRecordingAsync() async {
        guard !isPreparing else { return }

        isPreparing = true
        print("[ChatViewModel] 开始预连接...")

        let success = await AliyunASRService.shared.prepare()

        await MainActor.run {
            isPreparing = false
            if success {
                print("[ChatViewModel] 预连接完成")
            } else {
                print("[ChatViewModel] 预连接失败")
            }
        }
    }

    // MARK: - Chat Session Tracking

    /// 记录一次对话，增加对话次数
    func recordChatInteraction() {
        // Load user
        let user = DataStore.loadUser()

        // Increment chat count (both today and total)
        user.cloudCoinSystem.incrementChatCount()

        // Save user
        DataStore.shared.saveUser(user)
    }

    /// 结束对话会话，统计学习时长并检查打卡
    /// 在退出对话页时调用
    func finishSession() {
        let user = DataStore.loadUser()

        // Calculate study time: >30秒算1分钟，<30秒不算
        var earnedCoins = 0
        if let startTime = sessionStartTime {
            let totalSeconds = Date().timeIntervalSince(startTime)
            let studyMinutes: Int
            let fullMinutes = Int(totalSeconds) / 60
            let remainingSeconds = Int(totalSeconds) % 60

            // >30秒算1分钟
            if remainingSeconds >= 30 {
                studyMinutes = fullMinutes + 1
            } else {
                studyMinutes = fullMinutes
            }

            if studyMinutes > 0 {
                // 更新用户学习时长
                user.totalStudyTime += studyMinutes
                // 获得云朵币（1分钟=1币）
                earnedCoins = user.cloudCoinSystem.earnCoinsFromStudy(minutes: studyMinutes)
            }
        }

        // Try auto check-in
        let checkInCoins = user.cloudCoinSystem.performCheckIn()
        if checkInCoins > 0 {
            earnedCoins += checkInCoins
            checkInMessage = "今日打卡成功！获得 \(checkInCoins) 云朵币"
        }

        // Save user
        DataStore.shared.saveUser(user)

        sessionEarnedCoins += earnedCoins
        sessionStartTime = nil  // didSet 会自动清除 UserDefaults
    }

    /// 获取当前对话次数
    var todayChatCount: Int {
        let user = DataStore.loadUser()
        return user.cloudCoinSystem.todayChatCount
    }

    /// 检查今日是否已打卡
    var isCheckedInToday: Bool {
        let user = DataStore.loadUser()
        return user.cloudCoinSystem.isCheckedInToday
    }

    /// 预连接 WebSocket（直接进入页面时调用）
    func prepareRecording() {
        print("[ChatViewModel] prepareRecording() 被调用，isPreparing: \(isPreparing)")
        guard !isPreparing else { return }

        isPreparing = true

        Task {
            print("[ChatViewModel] 开始预连接...")
            // 直接使用 ASR 服务预连接
            let success = await AliyunASRService.shared.prepare()
            await MainActor.run {
                isPreparing = false
                if success {
                    print("[ChatViewModel] 预连接完成")
                } else {
                    print("[ChatViewModel] 预连接失败")
                    showNetworkErrorToast("语音服务连接失败，请重试")
                }
            }
        }
    }

    // 是否使用流式 TTS（默认开启）
    var useStreamingTTS: Bool = true

    /// 流式播放中的消息 ID（用于保持动画状态）
    private var streamingPlayingMessageId: UUID?

    private func addAIMessage(_ text: String) async {
        // Strip emojis for TTS but keep them in the displayed message
        let ttsText = text.removingEmoji
        print("添加到消息的文本: \(text)")
        print("TTS文本: \(ttsText)")

        let message = ChatMessage(text: text, speaker: .ai)
        messages.append(message)

        // 尝试使用流式 TTS
        if useStreamingTTS {
            await addAIMessageWithStreamingTTS(ttsText, messageId: message.id)
        } else {
            // 使用非流式 TTS
            await addAIMessageWithNonStreamingTTS(ttsText, messageId: message.id)
        }
    }

    /// 使用流式 TTS
    private func addAIMessageWithStreamingTTS(_ text: String, messageId: UUID) async {
        do {
            // 重置累积的音频数据
            QwenTTSRealtimeService.shared.reset()

            // 标记正在流式播放
            streamingPlayingMessageId = messageId

            // 用于等待音频完成的信号
            let audioComplete = AsyncStream<Bool?> { continuation in
                // 标记是否已完成
                var isFinished = false

                QwenTTSRealtimeService.shared.onAudioChunk = { [weak self] _ in
                    Task { @MainActor in
                        // 只在第一次设置播放状态
                        if self?.currentlyPlayingMessageId == nil {
                            self?.currentlyPlayingMessageId = messageId
                            if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                                self?.messages[index].isPlaying = true
                            }
                        }
                    }
                }

                QwenTTSRealtimeService.shared.onComplete = { [weak self] audioData in
                    Task { @MainActor in
                        guard !isFinished else { return }
                        isFinished = true
                        print("[ChatViewModel] onComplete 回调，音频长度: \(audioData.count)")
                        // 只保存音频数据，动画由 updatePlayingState 控制
                        if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                            self?.messages[index].audioData = audioData
                            print("[ChatViewModel] 音频已缓存到消息，长度: \(audioData.count)")
                            // 清理超出限制的音频缓存
                            self?.cleanupAudioCacheIfNeeded()
                        }
                        continuation.yield(true)
                        continuation.finish()
                    }
                }

                QwenTTSRealtimeService.shared.onError = { error in
                    guard !isFinished else { return }
                    isFinished = true
                    print("[ChatViewModel] TTS 错误: \(error)")
                    continuation.yield(false)
                    continuation.finish()
                }

                // 超时机制：10 秒内没有收到音频数据，认为失败
                Task {
                    try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 秒
                    if !isFinished {
                        isFinished = true
                        print("[ChatViewModel] 流式 TTS 超时，回退到非流式")
                        continuation.yield(nil)
                        continuation.finish()
                    }
                }
            }

            // 连接 WebSocket
            try await QwenTTSRealtimeService.shared.connect()
            print("[ChatViewModel] WebSocket 连接成功")

            // 配置 session（会等待 session.updated 确认）
            try await QwenTTSRealtimeService.shared.updateSession()
            print("[ChatViewModel] Session 配置成功")

            // 发送文本
            try await QwenTTSRealtimeService.shared.appendText(text)
            print("[ChatViewModel] 文本已发送: \(text.prefix(50))...")

            // 等待服务器开始处理（server_commit 模式会在收到文本后自动开始生成）
            try await Task.sleep(nanoseconds: 200_000_000)  // 0.2 秒

            // 结束会话（告诉服务器文本发送完毕）
            QwenTTSRealtimeService.shared.finish()
            print("[ChatViewModel] 流式 TTS 文本已发送，等待音频...")

            // 等待音频数据完成
            var result: Bool? = nil
            for await value in audioComplete {
                result = value
                break
            }

            if result == true {
                print("[ChatViewModel] 流式 TTS 完成")
            } else {
                // 超时或出错，回退到非流式 TTS
                print("[ChatViewModel] 流式 TTS 失败，回退到非流式")
                throw TTSSError.serverError("等待音频超时")
            }

        } catch {
            print("[ChatViewModel] 流式 TTS 失败，回退到非流式: \(error)")
            streamingPlayingMessageId = nil
            // 回退到非流式 TTS
            await addAIMessageWithNonStreamingTTS(text, messageId: messageId)
        }
    }

    /// 使用非流式 TTS（原有逻辑）
    private func addAIMessageWithNonStreamingTTS(_ text: String, messageId: UUID) async {
        if let audioData = await TTSService.shared.speak(text, for: messageId) {
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].audioData = audioData
                // 清理超出限制的音频缓存
                cleanupAudioCacheIfNeeded()
            }
        } else {
            // 非 流式 TTS 也失败，显示网络错误提示
            print("[ChatViewModel] 非流式 TTS 也失败，显示网络错误提示")
            await MainActor.run {
                showNetworkErrorToast("语音播放失败，请检查网络后重试")
            }
        }
    }


    func sendMessage(_ text: String, voiceData: Data? = nil) async {
        guard !text.isEmpty else { return }

        // Add user message（同时保存录音数据）
        messages.append(ChatMessage(text: text, speaker: .user, userVoiceData: voiceData))

        // Record chat interaction for cloud coin system (only for user messages)
        await MainActor.run {
            self.recordChatInteraction()
        }

        // Use AI to respond
        await generateAIResponse(to: text)
    }

    private func generateAIResponse(to text: String) async {
        isLoading = true

        do {
            // Get current messages as history (excluding the last user message we just added)
            let historyMessages = messages.dropLast()
            let response = try await AIChatService.shared.sendMessage(text, lessonId: currentLesson?.id ?? 1, historyMessages: Array(historyMessages))
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
        // ===== 关键步骤：先停止 TTS 播放和动画 =====
        // 用户录音优先级高于 TTS 播放
        stopAllPlayback()

        // 记录录音开始时间
        recordingStartTime = Date()

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
                print("[ChatViewModel] isRecording 变化为: \(recording)")
            }
            .store(in: &cancellables)

        recognizedText = ""
        isInCancelZone = false
        // 注意：isRecording 状态由 SpeechRecognizer 的回调设置，不在这里立即设置
        // 这样可以确保 UI 只在真正开始录音后才显示录音状态

        do {
            try speechRecognizer?.startRecording()
        } catch {
            errorMessage = "无法开始录音，请检查麦克风权限"
            isRecording = false
            speechRecognizer = nil
        }
    }

    func cancelRecording() {
        // ===== 第1步：立即更新UI =====
        isRecording = false
        recognizedText = ""
        cancellables.removeAll()
        speechRecognizer = nil

        // ===== 第2步：异步清理ASR =====
        // 直接使用ASR服务取消录音（不发送commit）
        // 注意：不调用 resetRecordingState()，保持 isSessionCancelled 标志
        AliyunASRService.shared.cancelRecording()

        print("[ChatViewModel] 录音已取消")

        // 如果 WebSocket 连接断开，尝试重新预连接
        if !AliyunASRService.shared.isReady {
            print("[ChatViewModel] 连接已断开，重新预连接...")
            prepareRecording()
        }
    }

    func stopRecording() {
        guard speechRecognizer != nil else {
            isRecording = false
            return
        }

        // ===== 第1步：计算录音时长 =====
        let recordingDuration: TimeInterval
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        } else {
            recordingDuration = 0
        }

        // ===== 第2步：立即更新UI，让用户感知到操作响应 =====
        isRecording = false
        recognizedText = ""
        cancellables.removeAll()
        speechRecognizer = nil
        recordingStartTime = nil

        // ===== 第3步：检查录音时长是否足够 =====
        if recordingDuration < 0.5 {
            // 录音时间太短，直接忽略（不显示任何提示）
            print("[ChatViewModel] 录音时长 \(recordingDuration)s 太短，忽略")
            AliyunASRService.shared.cancelRecording()
            AliyunASRService.shared.resetRecordingState()
            return
        }

        // 通知ASR停止录音（发送commit，触发最终识别）
        _ = AliyunASRService.shared.stopRecording()

        // ===== 第4步：检查是否检测到有效音频 =====
        let hasValidAudio = AliyunASRService.shared.hasDetectedValidAudio()
        print("[ChatViewModel] 检测到有效音频: \(hasValidAudio)")

        // ===== 第5步：延迟处理识别结果（保证准确率）=====
        // 等待1秒让ASR返回最终结果（最后的音频需要处理时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            // 检查是否检测到有效音频（用于过滤静音误识别）
            guard hasValidAudio else {
                print("[ChatViewModel] 未检测到有效音频，忽略识别结果")
                AliyunASRService.shared.resetRecordingState()
                return
            }

            // 获取最终识别结果
            let finalText = AliyunASRService.shared.transcript

            // 获取录音数据（在 resetRecordingState 之前）
            let voiceData = AliyunASRService.shared.getRecordedAudioData()

            // Clean up ASR状态
            AliyunASRService.shared.resetRecordingState()

            // Validate the recognized text
            let trimmedText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)

            print("[ChatViewModel] 最终识别文本: '\(trimmedText)'")

            // ===== 第6步：先检查网络连接 =====
            Task { [voiceData] in
                // 尝试连接 TTS WebSocket（用于判断网络是否可用）
                let ttsConnected = await self.ensureTTSConnection()
                if !ttsConnected {
                    // 断网，显示 Toast 并不发送消息
                    await MainActor.run {
                        self.showNetworkErrorToast()
                    }
                    return
                }

                // ===== 第7步：网络正常，验证文本并发送 =====
                await MainActor.run {
                    // Check if speech is too short (less than 2 characters)
                    if trimmedText.count < 2 {
                        // 录音内容太短，显示 Toast 提示
                        self.showNetworkErrorToast("没听清楚，请重新说")
                        return
                    }
                }

                // 发送消息（带上用户录音数据）
                await self.sendMessage(trimmedText, voiceData: voiceData)
            }
        }
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
