import SwiftUI
import AVFoundation

struct ScoreResultView: View {
    let score: ScoreResult
    var onDismiss: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var showStars = false
    @State private var animatedScore: Int = 0
    @State private var showBars = false
    @State private var showConfetti = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "FFF7ED"), Color(hex: "FFFBEB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(hex: "F3F4F6")))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Stars + Overall Score
                        overallScoreSection

                        // Four dimension scores
                        dimensionScoresSection

                        // Session stats
                        sessionStatsSection

                        // Sentence correction (grammar/expression errors)
                        if !score.grammarDetails.isEmpty {
                            sentenceCorrectionSection
                        }

                        // Pronunciation correction
                        if !score.pronunciationDetails.isEmpty {
                            pronunciationCorrectionSection
                        }

                        // Teacher feedback
                        feedbackSection

                        // Cloud coins earned
                        if score.earnedCoins > 0 {
                            coinRewardSection
                        }

                        // Action buttons
                        actionButtons
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Stars staggered animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showStars = true
        }

        // Score count-up animation
        let target = score.overallScore
        let duration = 1.5
        let steps = 30
        let interval = duration / Double(steps)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * interval) {
                withAnimation(.linear(duration: interval)) {
                    animatedScore = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }

        // Progress bars
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            showBars = true
        }

        // Confetti for high scores
        if score.overallScore >= 85 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showConfetti = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Overall Score Section

    private var overallScoreSection: some View {
        VStack(spacing: 16) {
            // Stars
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < score.starRating ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundStyle(index < score.starRating ? Color(hex: "F59E0B") : Color(hex: "D1D5DB"))
                        .scaleEffect(showStars ? 1.0 : 0.3)
                        .opacity(showStars ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1 + 0.3),
                            value: showStars
                        )
                }
            }

            // Score number
            Text("\(animatedScore)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("综合得分")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6B7280"))

            // Encouragement
            Text(score.encouragement)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "F97316"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Dimension Scores

    private var dimensionScoresSection: some View {
        VStack(spacing: 12) {
            DimensionBar(label: "词汇", score: score.vocabularyScore, color: Color(hex: "3B82F6"), animate: showBars)
            DimensionBar(label: "语法", score: score.grammarScore, color: Color(hex: "8B5CF6"), animate: showBars)
            DimensionBar(label: "发音", score: score.pronunciationScore, color: Color(hex: "10B981"), animate: showBars)
            DimensionBar(label: "流利", score: score.fluencyScore, color: Color(hex: "F59E0B"), animate: showBars)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Session Stats

    private var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("对话统计", systemImage: "chart.bar.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatItem(label: "对话轮数", value: "\(score.stats.totalTurns)")
                StatItem(label: "学习时长", value: formatDuration(score.stats.sessionDuration))
                StatItem(label: "正确率", value: score.stats.correctCount + score.stats.correctedCount > 0
                    ? "\(Int(Double(score.stats.correctCount) / Double(score.stats.correctCount + score.stats.correctedCount) * 100))%"
                    : "--")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Sentence Correction (句子纠错)

    private var sentenceCorrectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("句子纠错", systemImage: "text.badge.checkmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            ForEach(Array(score.grammarDetails.enumerated()), id: \.offset) { _, detail in
                VStack(alignment: .leading, spacing: 6) {
                    // 错误原句 + 播放按钮（紧挨句子）
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "EF4444"))

                        Text(detail.original)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2937"))
                            .strikethrough(detail.corrected != nil, color: Color(hex: "EF4444").opacity(0.5))

                        if detail.audioData != nil {
                            Button(action: { playAudio(detail.audioData) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "3B82F6"))
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color(hex: "EFF6FF")))
                            }
                        }
                    }

                    // 正确表达
                    if let corrected = detail.corrected {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "10B981"))
                            Text(corrected)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "10B981"))
                        }
                        .padding(.leading, 20)
                    }

                    // 说明
                    if let explanation = detail.explanation {
                        Text(explanation)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .padding(.leading, 20)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Pronunciation Correction (发音纠错)

    private var pronunciationCorrectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("发音纠错", systemImage: "waveform")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            ForEach(Array(score.pronunciationDetails.enumerated()), id: \.offset) { _, detail in
                VStack(alignment: .leading, spacing: 8) {
                    // 学生发音句子（错误单词红色）+ 问题描述在右边
                    HStack(alignment: .top, spacing: 6) {
                        // 句子（错误单词红色高亮）+ 播放学生录音
                        HStack(spacing: 6) {
                            highlightedSentence(detail.sentence, errorWords: detail.errorWords)
                                .font(.system(size: 14, weight: .medium))

                            if detail.audioData != nil {
                                Button(action: { playAudio(detail.audioData) }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "3B82F6"))
                                        .frame(width: 26, height: 26)
                                        .background(Circle().fill(Color(hex: "EFF6FF")))
                                }
                            }
                        }

                        Spacer()

                        // 发音问题描述
                        Text(detail.issue)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 120, alignment: .trailing)
                    }

                    // 正确发音（可朗读）
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "10B981"))

                        Text(detail.correction)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "10B981"))

                        Button(action: { speakText(detail.correction) }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "10B981"))
                        }
                    }
                    .padding(.leading, 4)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Highlighted Sentence (错误单词红色)

    private func highlightedSentence(_ sentence: String, errorWords: [String]) -> Text {
        let words = sentence.split(separator: " ").map(String.init)
        let lowercaseErrors = errorWords.map { $0.lowercased() }
        var result = Text("")
        for (index, word) in words.enumerated() {
            if index > 0 {
                result = result + Text(" ")
            }
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if lowercaseErrors.contains(cleanWord) {
                result = result + Text(word).foregroundColor(Color(hex: "EF4444"))
            } else {
                result = result + Text(word).foregroundColor(Color(hex: "1F2937"))
            }
        }
        return result
    }

    // MARK: - Audio Playback

    private func playAudio(_ data: Data?) {
        guard let data = data else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
        } catch {
            print("[ScoreResultView] 播放音频失败: \(error)")
        }
    }

    /// 使用系统 TTS 朗读正确发音
    private func speakText(_ text: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("老师点评", systemImage: "lightbulb.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            Text(score.feedback)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "374151"))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Coin Reward

    private var coinRewardSection: some View {
        HStack(spacing: 12) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("获得 \(score.earnedCoins) 云朵币!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "F59E0B"))

                Text(score.overallScore >= 95 ? "超级棒！满分奖励" : "优秀表现奖励")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "FFFBEB"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "F59E0B").opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                onDismiss()
                onContinue()
            }) {
                Text("再练一次")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "F97316"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "F97316"), lineWidth: 2)
                    )
            }

            Button(action: onDismiss) {
                Text("返回")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes > 0 {
            return "\(minutes)分钟"
        }
        return "\(seconds)秒"
    }
}

// MARK: - Dimension Bar

struct DimensionBar: View {
    let label: String
    let score: Int
    let color: Color
    let animate: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "6B7280"))
                .frame(width: 32, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F3F4F6"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: animate ? geometry.size.width * CGFloat(score) / 100.0 : 0, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(score)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "1F2937"))

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "F9FAFB"))
        )
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = time - particle.startTime
                    guard age < particle.lifetime else { continue }

                    let progress = age / particle.lifetime
                    let x = particle.startX + sin(age * particle.wobbleSpeed) * particle.wobbleAmount
                    let y = particle.startY + age * particle.fallSpeed
                    let opacity = 1.0 - progress

                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = opacity
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: particle.size > 6 ? 1 : 3),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            let now = Date().timeIntervalSinceReferenceDate
            let screenWidth = UIScreen.main.bounds.width
            let colors: [Color] = [
                Color(hex: "F97316"), Color(hex: "F59E0B"),
                Color(hex: "EF4444"), Color(hex: "3B82F6"),
                Color(hex: "10B981"), Color(hex: "8B5CF6")
            ]

            particles = (0..<50).map { _ in
                ConfettiParticle(
                    startX: Double.random(in: 0...screenWidth),
                    startY: Double.random(in: -50...(-10)),
                    fallSpeed: Double.random(in: 80...160),
                    wobbleSpeed: Double.random(in: 2...5),
                    wobbleAmount: Double.random(in: 20...50),
                    size: Double.random(in: 4...10),
                    color: colors.randomElement()!,
                    lifetime: Double.random(in: 2.5...4.0),
                    startTime: now + Double.random(in: 0...0.5)
                )
            }
        }
    }
}

struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let fallSpeed: Double
    let wobbleSpeed: Double
    let wobbleAmount: Double
    let size: Double
    let color: Color
    let lifetime: Double
    let startTime: Double
}
