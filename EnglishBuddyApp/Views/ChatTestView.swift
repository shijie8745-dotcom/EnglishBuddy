import SwiftUI
import Combine

struct ChatTestView: View {
    @State private var viewModel = ChatTestViewModel()
    @State private var aiInputText = ""
    @State private var userInputText = ""
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

                // Messages list
                messagesList

                // Input area
                inputArea
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            viewModel.requestSpeechAuthorization()
        }
        .onDisappear {
            viewModel.clearAudioCache()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(hex: "F97316"))

                Text("测试模式")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            Spacer()

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
                }
                .padding(.horizontal, 12)
                .padding(.top, 60)
                .padding(.bottom, 16)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation {
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Top divider
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            // AI Input
            HStack(spacing: 8) {
                TextField("输入AI对话内容...", text: $aiInputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))

                Button(action: {
                    sendAIMessage()
                }) {
                    Text("发送AI")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
                .disabled(aiInputText.isEmpty)
            }
            .padding(.horizontal, 16)

            // User Input
            HStack(spacing: 8) {
                TextField("输入用户对话内容...", text: $userInputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))

                Button(action: {
                    sendUserMessage()
                }) {
                    Text("发送用户")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(userInputText.isEmpty)
            }
            .padding(.horizontal, 16)

            // Hint
            Text("手动输入测试模式")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .safeAreaPadding(.bottom)
    }

    private func sendAIMessage() {
        guard !aiInputText.isEmpty else { return }
        viewModel.addAIMessage(aiInputText)
        aiInputText = ""
    }

    private func sendUserMessage() {
        guard !userInputText.isEmpty else { return }
        viewModel.addUserMessage(userInputText)
        userInputText = ""
    }
}

// MARK: - ViewModel
@Observable
class ChatTestViewModel {
    var messages: [ChatMessage] = []
    var currentlyPlayingMessageId: UUID?

    private var ttsObservation: AnyCancellable?
    private var speechRecognizer: SpeechRecognizer?

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

    func addAIMessage(_ text: String) {
        let message = ChatMessage(text: text, speaker: .ai)
        messages.append(message)

        // 测试模式使用系统 TTS
        Task {
            _ = await TTSService.shared.speak(text, for: message.id, forceSystemTTS: true)
        }
    }

    func addUserMessage(_ text: String) {
        let message = ChatMessage(text: text, speaker: .user)
        messages.append(message)

        // 测试模式使用系统 TTS
        Task {
            _ = await TTSService.shared.speak(text, for: message.id, forceSystemTTS: true)
        }
    }

    func togglePlay(for message: ChatMessage) {
        guard !message.isError else { return }

        if currentlyPlayingMessageId == message.id {
            TTSService.shared.stop()
            return
        }

        TTSService.shared.stop()

        // 清除所有播放状态
        for index in messages.indices {
            messages[index].isPlaying = false
        }
        currentlyPlayingMessageId = nil

        // 测试模式使用系统 TTS
        Task {
            _ = await TTSService.shared.speak(message.text, for: message.id, forceSystemTTS: true)
        }
    }

    func clearAudioCache() {
        for index in messages.indices {
            messages[index].audioData = nil
            messages[index].userVoiceData = nil
            messages[index].isPlaying = false
        }
        currentlyPlayingMessageId = nil
        TTSService.shared.stop()
    }

    func requestSpeechAuthorization() {
        // 在测试模式下也需要请求授权，因为 TTS 需要音频会话
        let recognizer = SpeechRecognizer()
        recognizer.requestAuthorization { _ in }
    }
}

#Preview {
    NavigationStack {
        ChatTestView()
    }
}
