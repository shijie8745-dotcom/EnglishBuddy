import SwiftUI
import Observation

// MARK: - AITest ViewModel
@Observable
class AITestViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var inputText = ""
    var currentLesson: Lesson?
    var currentlyPlayingMessageId: UUID?
    var errorMessage: String?

    /// 当前正在播放的消息ID

    func loadInitialMessages(for lesson: Lesson) {
        currentLesson = lesson
        messages = []
        currentlyPlayingMessageId = nil

        // Start with an AI greeting
        Task {
            await generateAIResponse(to: "Hello! I'm ready to learn \(lesson.title).")
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

        // 使用系统TTS播放（forceSystemTTS: true 避免费用）
        Task {
            currentlyPlayingMessageId = message.id
            messages[messages.firstIndex(where: { $0.id == message.id })!].isPlaying = true

            let ttsText = message.text.removingEmoji
            TTSService.shared.speak(ttsText, speed: nil, forceSystemTTS: true)

            // 监听播放结束
            while TTSService.shared.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].isPlaying = false
                }
                if currentlyPlayingMessageId == message.id {
                    currentlyPlayingMessageId = nil
                }
            }
        }
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage(text: trimmedText, speaker: .user))
        inputText = ""

        // Use AI to respond
        await generateAIResponse(to: trimmedText)
    }

    private func generateAIResponse(to text: String) async {
        isLoading = true

        do {
            // Get current messages as history
            let historyMessages = messages.dropLast()
            let response = try await AIChatService.shared.sendMessage(
                text,
                lessonId: currentLesson?.id ?? 1,
                historyMessages: Array(historyMessages)
            )
            print("=== AI原始响应 ===")
            print(response)
            print("==================")

            isLoading = false
            await addAIMessage(response)
        } catch {
            // Fallback responses
            let fallbackResponses = [
                "Wonderful! You're speaking great English!",
                "Excellent! I can understand you perfectly!",
                "Great job! Keep practicing! You're doing amazing!",
                "Fantastic! You're learning so fast! I'm proud of you!",
                "Super! That was really good English! Keep going!"
            ]
            let randomResponse = fallbackResponses.randomElement() ?? fallbackResponses[0]
            isLoading = false
            await addAIMessage(randomResponse)
        }
    }

    private func addAIMessage(_ text: String) async {
        let message = ChatMessage(text: text, speaker: .ai)
        messages.append(message)

        // 自动使用系统TTS播放AI回复
        Task {
            let ttsText = text.removingEmoji
            currentlyPlayingMessageId = message.id
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index].isPlaying = true
            }

            TTSService.shared.speak(ttsText, speed: nil, forceSystemTTS: true)

            // 等待播放结束
            while TTSService.shared.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].isPlaying = false
                }
                if currentlyPlayingMessageId == message.id {
                    currentlyPlayingMessageId = nil
                }
            }
        }
    }
}

// MARK: - Main View
struct AITestView: View {
    @State private var viewModel = AITestViewModel()
    @State private var lessons: [Lesson] = LessonResourceManager.loadLessonsFromJSON()
    @State private var user = DataStore.loadUser()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    var currentLesson: Lesson? {
        guard let lessonId = user.currentPracticeLessonId else {
            return lessons.first
        }
        return lessons.first { $0.id == lessonId }
    }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                chatHeader

                // Messages list
                messagesList

                // Text Input Area
                textInputArea
            }
        }
        .onAppear {
            if let lesson = currentLesson {
                viewModel.loadInitialMessages(for: lesson)
            }
        }
        .onDisappear {
            TTSService.shared.stop()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: 0) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            // Title with lesson info
            VStack(spacing: 4) {
                HStack(spacing: 10) {
                    teacherAvatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(hex: "FED7AA"), lineWidth: 2))

                    Text("AI 测试")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))
                }

                // Show current lesson
                if let lesson = currentLesson {
                    Text("Unit \(lesson.id): \(lesson.title)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "F97316"))
                }
            }

            Spacer()

            // Spacer for alignment
            Color.clear.frame(width: 40, height: 40)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Messages List
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            isPlaying: viewModel.currentlyPlayingMessageId == message.id,
                            onTap: {
                                viewModel.togglePlay(for: message)
                            }
                        )
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 24)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
        if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }

    // MARK: - Text Input Area
    private var textInputArea: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            // Input container
            HStack(spacing: 12) {
                // Text input field
                TextField("输入中文或英文...", text: $viewModel.inputText)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "1F2937"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "F3F4F6"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                    )
                    .focused($isInputFocused)
                    // 禁用自动大写和自动纠正，确保中文输入正常
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                // Send button
                Button(action: {
                    isInputFocused = false
                    Task {
                        await viewModel.sendMessage(viewModel.inputText)
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            viewModel.inputText.isEmpty
                            ? Color(hex: "D1D5DB")
                            : Color(hex: "F97316")
                        )
                }
                .disabled(viewModel.inputText.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: viewModel.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

// MARK: - Chat Bubble (Reused from ChatView)
struct AITestChatBubble: View {
    let message: ChatMessage
    let isPlaying: Bool
    let onTap: () -> Void

    var isAI: Bool { message.speaker == .ai }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isAI {
                aiAvatar
                    .padding(.trailing, 8)
            } else {
                Spacer()
            }

            // 消息内容
            HStack(alignment: .center, spacing: 6) {
                // 用户消息：动画在左
                if !isAI && isPlaying {
                    PlayingIndicator(color: Color(hex: "3B82F6"))
                        .frame(width: 20, height: 20)
                }

                // 气泡
                EmojiText(text: message.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(isAI ? Color(hex: "F97316") : Color(hex: "3B82F6"))
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap()
                    }

                // AI消息：动画在右
                if isAI && isPlaying {
                    PlayingIndicator()
                        .frame(width: 20, height: 20)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isAI ? .leading : .trailing)

            if isAI {
                Spacer()
            } else {
                userAvatar
                    .padding(.leading, 8)
            }
        }
    }

    private var aiAvatar: some View {
        teacherAvatarImage
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(hex: "F97316").opacity(0.5), lineWidth: 2))
    }

    private var userAvatar: some View {
        Circle()
            .fill(Color(hex: "DBEAFE"))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: "person.fill").font(.system(size: 16)).foregroundStyle(Color(hex: "3B82F6")))
    }
}

// MARK: - Helper Views (Reused from ChatView)

private var teacherAvatarImage: Image {
    // Try multiple paths to find teacher.png
    let possiblePaths = [
        "/Users/wjsun/.claude/dice-projects/learning-assistant/teacher.png",
        Bundle.main.path(forResource: "teacher", ofType: "png"),
        Bundle.main.bundlePath + "/Resources/teacher.png",
        Bundle.main.bundlePath + "/teacher.png"
    ]

    for path in possiblePaths {
        if let path = path, FileManager.default.fileExists(atPath: path),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
    }

    return Image(systemName: "person.circle.fill")
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AITestView()
    }
}
