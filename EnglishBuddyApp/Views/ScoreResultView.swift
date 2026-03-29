import SwiftUI
import AVFoundation

struct ScoreResultView: View {
    let score: ScoreResult
    var isFromHistory: Bool = false
    var onDismiss: () -> Void = {}
    var onReturnHome: (() -> Void)? = nil
    var onContinue: () -> Void = {}

    @State private var showStars = false
    @State private var animatedScore: Int = 0
    @State private var showBars = false
    @State private var showConfetti = false
    @State private var audioPlayer: AVAudioPlayer?


    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        scoreAndDimensionsSection
                        statsSection
                        if !score.grammarDetails.isEmpty {
                            sentenceCorrectionSection
                        }
                        if !score.pronunciationDetails.isEmpty {
                            pronunciationCorrectionSection
                        }
                        feedbackSection
                        if score.earnedCoins > 0 {
                            coinRewardSection
                        }
                        // Bottom padding for sticky button
                        if !isFromHistory {
                            Spacer().frame(height: 70)
                        } else {
                            Spacer().frame(height: 20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Sticky button at bottom
                if !isFromHistory {
                    stickyActionButton
                }
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if !isFromHistory {
                Button(action: {
                    if let returnHome = onReturnHome {
                        returnHome()
                    } else {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "333333"))
                }
            } else {
                Spacer().frame(width: 32)
            }

            Spacer()

            Text("对话评分 · Unit\(score.lessonId) \(score.lessonTitle)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "333333"))
                .lineLimit(1)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "999999"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(hex: "F0F0F0")))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showStars = true
        }
        let target = score.overallScore
        let steps = 30
        let interval: Double = 1.5 / Double(steps)
        for i in 0...steps {
            let delay = 0.5 + Double(i) * interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let newVal = Int(Double(target) * Double(i) / Double(steps))
                withAnimation(.linear(duration: interval)) {
                    animatedScore = newVal
                }
            }
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            showBars = true
        }
        if score.overallScore >= 85 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { showConfetti = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation { showConfetti = false }
            }
        }
    }

    // MARK: - Score + Dimensions

    private var scoreAndDimensionsSection: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left: Overall score card
            overallScoreCard

            // Right: Dimension grid (same height as left)
            dimensionGrid
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var overallScoreCard: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 6)
            // Stars
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { index in
                    let filled = index < score.starRating
                    Image(systemName: filled ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(filled ? Color(hex: "F59E0B") : Color(hex: "D1D5DB"))
                        .scaleEffect(showStars ? 1.0 : 0.3)
                        .opacity(showStars ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1 + 0.3),
                            value: showStars
                        )
                }
            }

            // Big score with 分
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(animatedScore)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("分")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "F97316"))
            }

            // Encouragement
            Text(score.encouragement)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "666666"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 24)
            Spacer().frame(height: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var dimensionGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("各维度评分")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "333333"))

            VStack(spacing: 7) {
                HStack(spacing: 7) {
                    dimensionCard(
                        icon: "book.fill", label: "词汇",
                        value: score.vocabularyScore,
                        iconBg: Color(hex: "3B82F6"),
                        barColor: Color(hex: "3B82F6")
                    )
                    dimensionCard(
                        icon: "doc.text.fill", label: "语法",
                        value: score.grammarScore,
                        iconBg: Color(hex: "EF4444"),
                        barColor: Color(hex: "10B981")
                    )
                }
                HStack(spacing: 7) {
                    dimensionCard(
                        icon: "speaker.wave.2.fill", label: "发音",
                        value: score.pronunciationScore,
                        iconBg: Color(hex: "F59E0B"),
                        barColor: Color(hex: "3B82F6")
                    )
                    dimensionCard(
                        icon: "chart.line.uptrend.xyaxis", label: "流利",
                        value: score.fluencyScore,
                        iconBg: Color(hex: "10B981"),
                        barColor: Color(hex: "F59E0B")
                    )
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func dimensionCard(icon: String, label: String, value: Int, iconBg: Color, barColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(iconBg))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "333333"))
            }

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "333333"))
                Text("分")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "999999"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(hex: "F0F0F0"))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(barColor)
                        .frame(width: showBars ? geo.size.width * CGFloat(value) / 100.0 : 0, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("对话统计")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "333333"))

            HStack(spacing: 8) {
                statCard(
                    icon: "bubble.left.fill",
                    label: "对话轮数",
                    value: "\(score.stats.totalTurns)",
                    unit: "轮",
                    gradient: [Color(hex: "7C3AED"), Color(hex: "A78BFA")]
                )
                statCard(
                    icon: "clock.fill",
                    label: "学习时长",
                    value: formatDurationValue(score.stats.sessionDuration),
                    unit: formatDurationUnit(score.stats.sessionDuration),
                    gradient: [Color(hex: "F97316"), Color(hex: "FB923C")]
                )
                statCard(
                    icon: "book.fill",
                    label: "练习词汇",
                    value: "\(score.stats.vocabularyPracticed)",
                    unit: "个",
                    gradient: [Color(hex: "0EA5E9"), Color(hex: "38BDF8")]
                )
                statCard(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "正确率",
                    value: accuracyText,
                    unit: "%",
                    gradient: [Color(hex: "EC4899"), Color(hex: "F472B6")]
                )
            }
        }
    }

    private var accuracyText: String {
        let total = score.stats.correctCount + score.stats.correctedCount
        return total > 0 ? "\(Int(Double(score.stats.correctCount) / Double(total) * 100))" : "--"
    }

    private func statCard(icon: String, label: String, value: String, unit: String, gradient: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.white.opacity(0.25)))
                .padding(.bottom, 8)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 4)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .frame(height: 110)
        .background(
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .offset(x: 8, y: 8)
            }
        )
    }

    // MARK: - Sentence Correction

    private var sentenceCorrectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("句子纠错")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "333333"))

            ForEach(Array(score.grammarDetails.enumerated()), id: \.offset) { _, detail in
                correctionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("你的回答")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "999999"))
                        HStack(spacing: 8) {
                            Text(detail.original)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "EF4444"))
                            if detail.audioData != nil {
                                Button(action: { playAudio(detail.audioData) }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "999999"))
                                }
                            }
                        }
                    }

                    if let corrected = detail.corrected {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("正确答案")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "999999"))
                            HStack(spacing: 8) {
                                Text(corrected)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "10B981"))
                                Button(action: { speakText(corrected) }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "10B981"))
                                }
                            }
                        }
                    }

                    if let explanation = detail.explanation {
                        HStack(alignment: .top, spacing: 8) {
                            Text(explanation)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "92400E"))
                            Button(action: { speakText(explanation) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "92400E").opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "FEF3C7"))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Pronunciation Correction

    private var pronunciationCorrectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发音纠错")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "333333"))

            ForEach(Array(score.pronunciationDetails.enumerated()), id: \.offset) { _, detail in
                correctionCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("你的发音")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "999999"))
                        HStack(spacing: 8) {
                            highlightedSentence(detail.sentence, errorWords: detail.errorWords)
                                .font(.system(size: 15, weight: .medium))
                            if detail.audioData != nil {
                                Button(action: { playAudio(detail.audioData) }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(hex: "999999"))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("正确发音")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "999999"))
                        HStack(spacing: 8) {
                            Text(detail.correction)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "10B981"))
                            Button(action: { speakText(detail.correction) }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(hex: "10B981"))
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("发音问题：\(detail.issue)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "92400E"))
                        Button(action: { speakText("发音问题：\(detail.issue)") }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "92400E").opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "FEF3C7"))
                    )
                }
            }
        }
    }

    // MARK: - Correction Card

    private func correctionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Highlighted Sentence

    private func highlightedSentence(_ sentence: String, errorWords: [String]) -> Text {
        let words = sentence.split(separator: " ").map(String.init)
        let lowercaseErrors = errorWords.map { $0.lowercased() }
        var result = Text("")
        for (i, word) in words.enumerated() {
            if i > 0 { result = result + Text(" ") }
            let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if lowercaseErrors.contains(clean) {
                result = result + Text(word).foregroundColor(Color(hex: "EF4444")).bold()
            } else {
                result = result + Text(word).foregroundColor(Color(hex: "333333"))
            }
        }
        return result
    }

    // MARK: - Audio

    private func playAudio(_ data: Data?) {
        guard let data = data else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
        } catch {
            print("[ScoreResultView] 播放音频失败: \(error)")
        }
    }

    private func speakText(_ text: String) {
        TTSService.shared.speak(text)
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("老师点评")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "333333"))

            Text(score.feedback)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "555555"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Coin Reward

    private var coinRewardSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "D97706"))
                    Text("恭喜获得奖励")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "92400E"))
                }

                HStack(alignment: .center, spacing: 4) {
                    Text("+\(score.earnedCoins)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: "D97706"))
                    Text("云朵币")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "D97706"))
                    Image("coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            }

            Spacer()

            Image(systemName: "cloud.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color(hex: "FBBF24").opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Sticky Action Button

    private var stickyActionButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                onDismiss()
                onContinue()
            }) {
                Text("再练一次")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.white)
    }

    // MARK: - Helpers

    private func formatDurationValue(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes > 0 ? "\(minutes)" : "\(seconds)"
    }

    private func formatDurationUnit(_ seconds: Int) -> String {
        return seconds >= 60 ? "分钟" : "秒"
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
                    let x = particle.startX + sin(age * particle.wobbleSpeed) * particle.wobbleAmount
                    let y = particle.startY + age * particle.fallSpeed
                    let opacity = 1.0 - age / particle.lifetime
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
            let w = UIScreen.main.bounds.width
            let colors: [Color] = [
                Color(hex: "F97316"), Color(hex: "F59E0B"),
                Color(hex: "EF4444"), Color(hex: "3B82F6"),
                Color(hex: "10B981"), Color(hex: "8B5CF6")
            ]
            particles = (0..<50).map { _ in
                ConfettiParticle(
                    startX: .random(in: 0...w), startY: .random(in: -50...(-10)),
                    fallSpeed: .random(in: 80...160), wobbleSpeed: .random(in: 2...5),
                    wobbleAmount: .random(in: 20...50), size: .random(in: 4...10),
                    color: colors.randomElement()!, lifetime: .random(in: 2.5...4.0),
                    startTime: now + .random(in: 0...0.5)
                )
            }
        }
    }
}

struct ConfettiParticle {
    let startX, startY, fallSpeed, wobbleSpeed, wobbleAmount, size: Double
    let color: Color
    let lifetime, startTime: Double
}
