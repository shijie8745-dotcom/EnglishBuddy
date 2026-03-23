import SwiftUI

struct AITestView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var currentLesson: Lesson?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            // Main content - same structure as ChatView
            VStack(spacing: 0) {
                // Header
                chatHeader

                // Messages list
                messagesList

                // Text input area (replacing voice input)
                textInputArea
            }
        }
        .onAppear {
            loadPracticeLesson()
        }
        .onDisappear {
            viewModel.clearAudioCache()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Load Practice Lesson
    private func loadPracticeLesson() {
        let user = DataStore.loadUser()
        let lessons = LessonResourceManager.loadLessonsFromJSON()

        // Get current practice lesson from user settings
        let lessonId = user.currentPracticeLessonId ?? 1
        currentLesson = lessons.first { $0.id == lessonId }

        // Load initial messages for this lesson
        if let lesson = currentLesson {
            viewModel.loadInitialMessages(for: lesson)
        }
    }

    // MARK: - Chat Header (same as ChatView)
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

            // Title: AI Test + current unit info
            VStack(spacing: 4) {
                Text("AI Test")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                if let lesson = currentLesson {
                    Text("Unit \(lesson.id) - \(lesson.title)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Messages List (same as ChatView)
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
                .padding(.top, 16)
                .padding(.bottom, 16)
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
                proxy.scrollTo(lastId, anchor: .top)
            }
        }
        if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("typing", anchor: .top)
            }
        }
    }

    // MARK: - Text Input Area (replaces voice input)
    private var textInputArea: some View {
        VStack(spacing: 0) {
            // Top divider line
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            // Input field and send button
            HStack(spacing: 12) {
                // Text input field
                TextField("输入消息...", text: $inputText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F3F4F6"))
                    )

                // Send button
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: inputText.isEmpty ? [Color(hex: "D1D5DB"), Color(hex: "9CA3AF")] : [Color(hex: "F97316"), Color(hex: "EA580C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let textToSend = trimmedText
        inputText = ""

        Task {
            await viewModel.sendMessage(textToSend)
        }
    }
}

#Preview {
    NavigationStack {
        AITestView()
    }
}
