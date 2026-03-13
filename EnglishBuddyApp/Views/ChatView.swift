import SwiftUI

struct ChatView: View {
    let lesson: Lesson
    var isFromPractice: Bool = false
    @State private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

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
        .onAppear {
            viewModel.loadInitialMessages(for: lesson)
            viewModel.requestSpeechAuthorization()
        }
        .onDisappear {
            // 退出会话时清理音频缓存
            viewModel.clearAudioCache()
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

            // 学习伙伴 Amy 头像和名字
            HStack(spacing: 10) {
                teacherAvatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "FED7AA"), lineWidth: 2))

                Text("Amy")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
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

            VStack(spacing: 8) {
                // Real-time transcription display
                if viewModel.isRecording && !viewModel.recognizedText.isEmpty {
                    Text(viewModel.recognizedText)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }

                // Microphone button
                MicrophoneButton(
                    isRecording: viewModel.isRecording,
                    onPress: {
                        viewModel.startRecording()
                    },
                    onRelease: {
                        viewModel.stopRecording()
                    }
                )

                // Hint text
                Text(viewModel.isRecording ? "松开发送" : "按住说话")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .safeAreaPadding(.bottom)
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
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

            // 消息内容：动画 + 气泡（间距 6pt）
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

// MARK: - Playing Indicator
struct PlayingIndicator: View {
    @State private var animate = false
    var color: Color = Color(hex: "F97316")

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3, height: animate ? 16 : 6)
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animate
                    )
            }
        }
        .frame(width: 24, height: 24)
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Emoji Text (SwiftUI wrapper for emoji support)
struct EmojiText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var showFirst = false
    @State private var showSecond = false
    @State private var showThird = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            teacherAvatarImage
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(hex: "F97316").opacity(0.5), lineWidth: 2))

            HStack(spacing: 4) {
                Circle().fill(Color(hex: "9CA3AF")).frame(width: 8, height: 8).opacity(showFirst ? 1 : 0.3)
                Circle().fill(Color(hex: "9CA3AF")).frame(width: 8, height: 8).opacity(showSecond ? 1 : 0.3)
                Circle().fill(Color(hex: "9CA3AF")).frame(width: 8, height: 8).opacity(showThird ? 1 : 0.3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            Spacer()
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            showFirst = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showSecond = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showThird = true
            }
        }
    }
}

// MARK: - Microphone Button
struct MicrophoneButton: View {
    let isRecording: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Ripple animation when recording
            if isRecording {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                            rippleScale = 1.5
                            rippleOpacity = 0
                        }
                    }
                    .onDisappear {
                        rippleScale = 1.0
                        rippleOpacity = 0
                    }
            }

            // Button background - 无动画的直接状态切换
            Circle()
                .fill(isRecording ? Color.red : Color(hex: "F97316"))
                .frame(width: isRecording ? 72 : 64, height: isRecording ? 72 : 64)
                .shadow(
                    color: (isRecording ? Color.red : Color(hex: "F97316")).opacity(0.3),
                    radius: isRecording ? 12 : 8,
                    x: 0,
                    y: isRecording ? 6 : 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .overlay(
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: isRecording ? 28 : 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating, isActive: isRecording)
                )
        }
        .pressEvents {
            isPressed = true
            onPress()
        } onRelease: {
            isPressed = false
            onRelease()
        }
    }
}

// MARK: - Helper
private var starmanImage: Image {
    // Try multiple paths to find the image
    let possiblePaths = [
        Bundle.main.path(forResource: "starman", ofType: "png", inDirectory: "Assets"),
        Bundle.main.path(forResource: "starman", ofType: "png"),
        Bundle.main.bundlePath + "/Resources/Assets/starman.png",
        Bundle.main.bundlePath + "/Assets/starman.png"
    ]

    for path in possiblePaths {
        if let path = path, FileManager.default.fileExists(atPath: path),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
    }

    // Fallback - try to load from URL
    if let url = Bundle.main.url(forResource: "starman", withExtension: "png", subdirectory: "Assets"),
       let data = try? Data(contentsOf: url),
       let uiImage = UIImage(data: data) {
        return Image(uiImage: uiImage)
    }

    return Image("starman")
}

private var rabbitAvatarImage: Image {
    // Try multiple paths to find the image
    let possiblePaths = [
        "/Users/wjsun/.claude/dice-projects/learning-assistant/rabbit.png",
        Bundle.main.path(forResource: "rabbit", ofType: "png"),
        Bundle.main.bundlePath + "/Resources/rabbit.png",
        Bundle.main.bundlePath + "/rabbit.png"
    ]

    for path in possiblePaths {
        if let path = path, FileManager.default.fileExists(atPath: path),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
    }

    // Fallback to system image
    return Image(systemName: "hare.fill")
}

// 学习伙伴 Amy 的头像
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

    // Fallback to system image (person)
    return Image(systemName: "person.circle.fill")
}

// MARK: - Geometry Preference Key
struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ChatView(lesson: Lesson.mockLessons[0])
}
