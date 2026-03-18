import SwiftUI

struct ChatView: View {
    let lesson: Lesson
    var isFromPractice: Bool = false
    @State private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // Layer 1: Background + Main Content
            VStack(spacing: 0) {
                // Header
                chatHeader

                // Messages list - scrollable area
                messagesList

                // Bottom input area (white background, no buttons here during recording)
                inputAreaBackground
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Layer 2: Recording Overlay (covers from header bottom to screen bottom)
            if viewModel.isRecording {
                VStack(spacing: 0) {
                    // Header area - no overlay
                    Color.clear

                    // Messages + Input area - with overlay (fill remaining space)
                    Color.black
                        .opacity(0.5)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Layer 3: Recording UI Elements (above overlay)
            if viewModel.isRecording {
                RecordingElements(viewModel: viewModel)
            }

                    // Layer 4: Input Area with buttons (always on top, always interactive)
            VStack {
                Spacer()
                inputAreaButtons
            }
            .ignoresSafeArea(.container, edges: .bottom)
            // Ensure this layer is always above the overlay
            .zIndex(100)
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

    // MARK: - Input Area Background (white background only)
    private var inputAreaBackground: some View {
        VStack(spacing: 0) {
            // Top divider
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            // Bottom padding area (buttons are overlaid on top)
            // Height: 16 padding + 56 button + 16 padding = 88pt (without safe area)
            Color.white
                .frame(minHeight: 88)
        }
        .background(Color.white)
        .safeAreaPadding(.bottom)
    }

    // MARK: - Input Area Buttons (voice button + cancel button)
    private var inputAreaButtons: some View {
        GeometryReader { geometry in
            VoiceInputContainer(viewModel: viewModel)
                .padding(.horizontal, 16)
        }
        .frame(height: 88) // Match background height
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

// MARK: - Recording Elements (Voice Bubble, appears above overlay)
struct RecordingElements: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        GeometryReader { geometry in
            // Voice bubble - centered in the screen (below header)
            VoiceBubble(isInCancelZone: viewModel.isInCancelZone)
                .frame(width: 140, height: 100)
                .position(
                    x: geometry.size.width / 2,
                    y: (geometry.size.height - 60) / 2 + 60 // Center of area below header
                )
        }
    }
}

// MARK: - Voice Input Container (Buttons above overlay)
struct VoiceInputContainer: View {
    @Bindable var viewModel: ChatViewModel
    @State private var isPressed = false
    @State private var isInCancelZone = false
    @State private var cancelButtonFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cancel hint text + Cancel button - both positioned absolutely above voice button
                VStack(spacing: 0) {
                    // "松开取消" hint text (appears when over cancel button)
                    // Positioned above cancel button with 8px gap
                    Text("松开取消")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .opacity(viewModel.isRecording && isInCancelZone ? 1 : 0)
                        .offset(y: viewModel.isRecording && isInCancelZone ? 0 : 10)
                        .animation(.easeInOut(duration: 0.2), value: isInCancelZone)

                    Spacer().frame(height: 8)

                    // Cancel button - positioned 24px above voice button
                    CancelButton(isVisible: viewModel.isRecording, isHighlighted: isInCancelZone)
                        // Get the frame of cancel button in global coordinates
                        .background(
                            GeometryReader { cancelGeometry in
                                Color.clear
                                    .onChange(of: cancelGeometry.frame(in: .global)) { oldFrame, newFrame in
                                        cancelButtonFrame = newFrame
                                    }
                                    .onAppear {
                                        cancelButtonFrame = cancelGeometry.frame(in: .global)
                                    }
                            }
                        )
                }
                // Position cancel button area 36px above voice button (larger gap for better UX)
                .frame(width: geometry.size.width - 32, height: 52 + 8 + 20) // Same width as voice button (with padding)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 - 56/2 - 36 - 26 // Above centered voice button (36px gap)
                )

                // Main voice button - vertically centered in the container
                VoiceButton(
                    isRecording: viewModel.isRecording,
                    isDimmed: isInCancelZone,
                    text: viewModel.isRecording ? "松开发送" : "按住说话"
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 // Vertically centered
                )
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if !isPressed {
                                isPressed = true
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.startRecording()
                                }
                            }

                            // Check if finger is over cancel button frame
                            let fingerLocation = value.location
                            let expandedFrame = cancelButtonFrame.insetBy(dx: -30, dy: -30)
                            let shouldCancel = expandedFrame.contains(fingerLocation)

                            if shouldCancel != isInCancelZone {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isInCancelZone = shouldCancel
                                    viewModel.isInCancelZone = shouldCancel
                                }
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            if isInCancelZone {
                                viewModel.cancelRecording()
                            } else {
                                viewModel.stopRecording()
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isInCancelZone = false
                                viewModel.isInCancelZone = false
                            }
                        }
                )
            }
        }
        .frame(height: 120)
    }
}

// MARK: - Voice Button (Long Rounded Rectangle)
struct VoiceButton: View {
    let isRecording: Bool
    let isDimmed: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            LinearGradient(
                colors: isRecording
                    ? [Color(hex: "EF4444"), Color(hex: "DC2626")]
                    : [Color(hex: "F97316"), Color(hex: "EA580C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
        .shadow(
            color: (isRecording ? Color.red : Color(hex: "F97316")).opacity(isDimmed ? 0.1 : 0.35),
            radius: isDimmed ? 4 : 8,
            x: 0,
            y: isDimmed ? 2 : 4
        )
        .opacity(isDimmed ? 0.5 : 1.0)
        .scaleEffect(isRecording ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .animation(.easeInOut(duration: 0.15), value: isDimmed)
    }
}

// MARK: - Cancel Button (Same width as voice button, rounded rectangle)
struct CancelButton: View {
    let isVisible: Bool
    let isHighlighted: Bool

    var body: some View {
        Text("取消")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isHighlighted ? .white : Color(hex: "374151"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(isHighlighted ? Color(hex: "6B7280") : Color.white.opacity(0.9))
                    .shadow(
                        color: isHighlighted ? Color(hex: "6B7280").opacity(0.4) : Color.black.opacity(0.1),
                        radius: isHighlighted ? 6 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeInOut(duration: 0.2), value: isVisible)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}

// MARK: - Recording Overlay (In Chat Area Only)
struct RecordingOverlay: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gray overlay - covers entire parent (which is the ScrollView)
                Color.black
                    .opacity(viewModel.isRecording ? 0.5 : 0)

                // Content (only visible when recording)
                if viewModel.isRecording {
                    // Voice bubble - centered in the available space
                    VoiceBubble(isInCancelZone: viewModel.isInCancelZone)
                        .frame(width: 140, height: 100)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Voice Bubble with Wave Animation
struct VoiceBubble: View {
    let isInCancelZone: Bool

    var body: some View {
        ZStack {
            // Bubble background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: isInCancelZone
                            ? [Color(hex: "F87171"), Color(hex: "EF4444")]
                            : [Color(hex: "86EFAC"), Color(hex: "4ADE80")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: (isInCancelZone ? Color.red : Color.green).opacity(0.4),
                    radius: 16,
                    x: 0,
                    y: 8
                )

            // Content - only voice wave animation, no text
            VoiceWaveAnimation()
                .frame(height: 40)
        }
        .overlay(
            // Triangle pointer at bottom - aligned with bubble bottom edge
            Triangle()
                .fill(isInCancelZone ? Color(hex: "EF4444") : Color(hex: "4ADE80"))
                .frame(width: 24, height: 12)
                .offset(y: 6) // Half of triangle height to align top edge with bubble bottom
            , alignment: .bottom
        )
        .animation(.easeInOut(duration: 0.2), value: isInCancelZone)
    }
}

// MARK: - Voice Wave Animation
struct VoiceWaveAnimation: View {
    @State private var isAnimating = false

    let barCount = 8
    let barWidths: [CGFloat] = [4, 4, 4, 4, 4, 4, 4, 4]
    let barHeights: [CGFloat] = [12, 24, 32, 28, 36, 20, 32, 16]
    let delays: [Double] = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: barWidths[index], height: isAnimating ? barHeights[index] : barHeights[index] * 0.6)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(delays[index]),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Triangle Shape (Bubble Pointer)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Legacy Microphone Button (Kept for compatibility)
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
