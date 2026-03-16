import SwiftUI
import AVFoundation

struct AIChatTestView: View {
    let lesson: Lesson
    @State private var viewModel = AIChatTestViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header
                chatHeader

                // Messages list - scrollable area
                messagesList

                // Bottom input area
                inputArea
            }
            .ignoresSafeArea(.container, edges: .bottom)
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

            // AI 头像和名字
            HStack(spacing: 10) {
                teacherAvatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "FED7AA"), lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Amy")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text("AI测试模式")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "9CA3AF"))
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
                .padding(.top, 60)
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
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
        if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }

    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            HStack(spacing: 12) {
                // Text input field
                TextField("输入消息...", text: $viewModel.inputText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F3F4F6"))
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }

                // Send button
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Circle()
                        .fill(viewModel.inputText.isEmpty ? Color(hex: "D1D5DB") : Color(hex: "F97316"))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                }
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }
}

// MARK: - ViewModel
@Observable
class AIChatTestViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var currentlyPlayingMessageId: UUID?

    // 系统TTS（不使用API TTS，节省费用）
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        synthesizer.delegate = self
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage(text: trimmed, speaker: .user))
        inputText = ""

        // Get AI response
        Task {
            await getAIResponse(to: trimmed)
        }
    }

    private func getAIResponse(to text: String) async {
        isLoading = true

        do {
            let response = try await AIChatService.shared.sendMessage(text, lessonId: 0)
            isLoading = false

            // Add AI message
            let aiMessage = ChatMessage(text: response, speaker: .ai)
            messages.append(aiMessage)

            // 使用系统TTS朗读AI回复
            speakWithSystemTTS(response, for: aiMessage.id)

        } catch {
            isLoading = false
            messages.append(ChatMessage(text: "Sorry, I'm having trouble connecting. Please try again!", speaker: .ai))
        }
    }

    /// 使用系统TTS（不调用API，节省费用）
    private func speakWithSystemTTS(_ text: String, for messageId: UUID) {
        // 过滤掉emoji，系统TTS无法朗读
        let filteredText = text.filteringForTTS

        let utterance = AVSpeechUtterance(string: filteredText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // 较慢语速

        currentlyPlayingMessageId = messageId

        synthesizer.speak(utterance)
    }

    func togglePlay(for message: ChatMessage) {
        // 停止当前播放
        synthesizer.stopSpeaking(at: .immediate)

        if currentlyPlayingMessageId == message.id {
            // 正在播放，停止
            currentlyPlayingMessageId = nil
        } else {
            // 播放选中的消息
            currentlyPlayingMessageId = message.id
            speakWithSystemTTS(message.text, for: message.id)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AIChatTestViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentlyPlayingMessageId = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        currentlyPlayingMessageId = nil
    }
}

#Preview {
    AIChatTestView(lesson: Lesson.mockLessons[0])
}
