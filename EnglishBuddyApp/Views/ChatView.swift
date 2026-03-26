import SwiftUI

struct ChatView: View {
    let lesson: Lesson
    var isFromPractice: Bool = false
    @State private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode

    // Adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ZStack {
            // Layer 1: Background + Main Content (like HTML: header + chat-messages + voice-input-wrapper)
            VStack(spacing: 0) {
                // Header (fixed height, white background)
                chatHeader

                // Messages + Input Area (combined, with overlay on top when recording)
                ZStack {
                    // Messages list
                    messagesList

                    // Input area background (white bg + divider) - below overlay
                    VStack {
                        Spacer()
                        inputAreaWithDivider
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Layer 2: Recording Overlay (covers entire screen to top)
            if viewModel.isRecording {
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Layer 3: Recording UI Elements (Voice bubble, above overlay)
            if viewModel.isRecording {
                RecordingElements(viewModel: viewModel)
            }

            // Layer 4: Voice Input Buttons (cancel + voice, always on top like HTML voice-input-wrapper)
            VStack {
                Spacer()

                // Voice input buttons overlay (no background, just buttons)
                VoiceInputContainer(viewModel: viewModel, isCompact: isCompact)
                    .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                    .frame(height: AdaptiveLayout.Dimensions.voiceInputHeight(isCompact: isCompact))
                    .background(Color.clear) // Transparent, overlay is below
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // Layer 5: Toast 通知
            if viewModel.showToast {
                VStack {
                    Spacer()
                    Text(viewModel.toastMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(25)
                        .padding(.bottom, 120)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.showToast)
            }
        }
        .onAppear {
            viewModel.loadInitialMessages(for: lesson)
            viewModel.requestSpeechAuthorization()
        }
        .onDisappear {
            // 退出会话时统计学习时长并清理音频缓存
            viewModel.finishSession()
            viewModel.clearAudioCache()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Chat Header
    private var chatHeader: some View {
        let headerButtonSize = AdaptiveLayout.Dimensions.headerButtonSize(isCompact: isCompact)
        let avatarSize = AdaptiveLayout.Dimensions.avatarSize(isCompact: isCompact)
        return HStack(spacing: 0) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: headerButtonSize, height: headerButtonSize)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            // 学习伙伴 Emii 头像和名字
            HStack(spacing: 10) {
                teacherAvatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "FED7AA"), lineWidth: 2))

                Text("Emii")
                    .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            Spacer()

            // Spacer for alignment
            Color.clear.frame(width: headerButtonSize, height: headerButtonSize)
        }
        .frame(height: AdaptiveLayout.Dimensions.headerHeight(isCompact: isCompact))
        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Messages List
    private var messagesList: some View {
        let inputHeight = AdaptiveLayout.Dimensions.voiceInputHeight(isCompact: isCompact)
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            isPlaying: viewModel.currentlyPlayingMessageId == message.id,
                            onTap: {
                                viewModel.togglePlay(for: message)
                            },
                            isCompact: isCompact
                        )
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        TypingIndicator(isCompact: isCompact)
                            .id("typing")
                    }
                }
                .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                .padding(.top, AdaptiveLayout.Dimensions.headerHeight(isCompact: isCompact))
                .padding(.bottom, inputHeight + 48)
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
                // Scroll to make last message visible above input area
                proxy.scrollTo(lastId, anchor: .top)
            }
        }
        if viewModel.isLoading {
            withAnimation {
                proxy.scrollTo("typing", anchor: .top)
            }
        }
    }

    // MARK: - Input Area with Divider (white background - visible when not recording, covered when recording)
    private var inputAreaWithDivider: some View {
        VStack(spacing: 0) {
            // Top divider line
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 0.5)

            // White background area for buttons
            Color.white
                .frame(height: AdaptiveLayout.Dimensions.voiceInputHeight(isCompact: isCompact))
        }
        .safeAreaPadding(.bottom)
    }

}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    let isPlaying: Bool
    let onTap: () -> Void
    var isCompact: Bool = false

    var isAI: Bool { message.speaker == .ai }
    private var avatarSize: CGFloat { AdaptiveLayout.Dimensions.chatAvatarSize(isCompact: isCompact) }

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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
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
            .frame(maxWidth: AdaptiveLayout.Dimensions.chatBubbleMaxWidth(screenWidth: UIScreen.main.bounds.width, isCompact: isCompact), alignment: isAI ? .leading : .trailing)

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
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(hex: "F97316").opacity(0.5), lineWidth: 2))
    }

    private var userAvatar: some View {
        Circle()
            .fill(Color(hex: "DBEAFE"))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(Image(systemName: "person.fill").font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact))).foregroundStyle(Color(hex: "3B82F6")))
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
    var isCompact: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
            .foregroundStyle(.white)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var showFirst = false
    @State private var showSecond = false
    @State private var showThird = false
    var isCompact: Bool = false

    private var avatarSize: CGFloat { AdaptiveLayout.Dimensions.chatAvatarSize(isCompact: isCompact) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            teacherAvatarImage
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
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
    @State private var isConnecting = false
    var isCompact: Bool = false

    private var inputHeight: CGFloat { AdaptiveLayout.Dimensions.voiceInputHeight(isCompact: isCompact) }
    private var buttonHeight: CGFloat { AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact) }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cancel hint text + Cancel button - both positioned absolutely above voice button
                VStack(spacing: 0) {
                    // "松开取消" hint text (appears when over cancel button)
                    // Positioned above cancel button with 8px gap，文字大小和取消按钮一致
                    Text("松开取消")
                        .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .medium))
                        .foregroundStyle(.white)
                        .opacity(viewModel.isRecording && isInCancelZone ? 1 : 0)
                        .offset(y: viewModel.isRecording && isInCancelZone ? 0 : 10)
                        .animation(.easeInOut(duration: 0.2), value: isInCancelZone)

                    Spacer().frame(height: 8)

                    // Cancel button - positioned 24px above voice button
                    CancelButton(isVisible: viewModel.isRecording, isHighlighted: isInCancelZone, isCompact: isCompact)
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
                // Position cancel button area 36px above voice button
                .frame(width: geometry.size.width - 32, height: buttonHeight + 8 + 20)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height - buttonHeight - 16 - 36 - 26 - 8 // Above voice button (36px gap + hint)
                )

                // Main voice button - at bottom of container with vertical centering in white bg
                VoiceButton(
                    isRecording: viewModel.isRecording,
                    isDimmed: isInCancelZone,
                    isConnecting: isConnecting,
                    text: buttonText,
                    isCompact: isCompact
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2 - 8 // Vertically centered in container, moved up more
                )
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            print("[ChatView] DragGesture onChanged, isPressed: \(isPressed), isConnecting: \(isConnecting)")

                            if !isPressed && !isConnecting {
                                isPressed = true
                                isConnecting = true
                                print("[ChatView] 开始连接并录音...")

                                // 启动录音（内部会处理连接）
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.startRecording()
                                }
                            }

                            // 只有在录音真正开始后才检查取消区域
                            if viewModel.isRecording {
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
                        }
                        .onEnded { _ in
                            print("[ChatView] DragGesture onEnded, isInCancelZone: \(isInCancelZone), isRecording: \(viewModel.isRecording), isConnecting: \(isConnecting)")
                            isPressed = false
                            isConnecting = false

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
        .frame(height: inputHeight) // Match the input area background height
    }

    private var buttonText: String {
        if isConnecting && !viewModel.isRecording {
            return "连接中..."
        } else if viewModel.isRecording {
            return "松开发送"
        } else {
            return "按住说话"
        }
    }
}

// MARK: - Voice Button (Long Rounded Rectangle)
struct VoiceButton: View {
    let isRecording: Bool
    let isDimmed: Bool
    let isConnecting: Bool
    let text: String
    var isCompact: Bool = false

    private var buttonHeight: CGFloat { AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact) }

    // 是否显示录音中状态（正在录音或连接中都显示录音样式）
    private var showRecordingStyle: Bool {
        isRecording || isConnecting
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .semibold))
                .foregroundStyle(.white)

            Text(text)
                .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
        .background(
            LinearGradient(
                colors: showRecordingStyle ? recordingColors : normalColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
        .shadow(
            color: showRecordingStyle ? Color.red.opacity(isDimmed ? 0.1 : 0.35) : Color(hex: "F97316").opacity(isDimmed ? 0.1 : 0.35),
            radius: isDimmed ? 4 : 8,
            x: 0,
            y: isDimmed ? 2 : 4
        )
        .opacity(isDimmed ? 0.5 : 1.0)
        .scaleEffect(showRecordingStyle ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: showRecordingStyle)
        .animation(.easeInOut(duration: 0.15), value: isDimmed)
    }

    private var iconName: String {
        showRecordingStyle ? "waveform" : "mic.fill"
    }

    private var recordingColors: [Color] {
        [Color(hex: "EF4444"), Color(hex: "DC2626")]
    }

    private var normalColors: [Color] {
        [Color(hex: "F97316"), Color(hex: "EA580C")]
    }
}

// MARK: - Cancel Button (Same width as voice button, rounded rectangle)
struct CancelButton: View {
    let isVisible: Bool
    let isHighlighted: Bool
    var isCompact: Bool = false

    private var buttonHeight: CGFloat { AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact) }

    // 默认状态：浅灰色背景，白色文字
    // 高亮状态：白色背景，黑色文字
    var body: some View {
        Text("取消")
            .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .medium))
            .foregroundStyle(isHighlighted ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(isHighlighted ? Color.white : Color(hex: "9CA3AF"))
                    .shadow(
                        color: isHighlighted ? Color.black.opacity(0.15) : Color.black.opacity(0.2),
                        radius: isHighlighted ? 6 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(isHighlighted ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
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
                .offset(y: 10) // Triangle top edge aligns with bubble bottom edge
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
    Image("teacher")
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
