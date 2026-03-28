import SwiftUI

struct ScoreResultView: View {
    let score: ScoreResult
    var onDismiss: () -> Void = {}
    var onContinue: () -> Void = {}

    @State private var showStars = false
    @State private var animatedScore: Int = 0
    @State private var showBars = false
    @State private var showConfetti = false

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

                        // Vocabulary details
                        if !score.vocabularyDetails.isEmpty {
                            vocabularyDetailsSection
                        }

                        // Sentence details
                        if !score.sentenceDetails.isEmpty {
                            sentenceDetailsSection
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
            DimensionBar(label: "句型", score: score.sentencePatternScore, color: Color(hex: "8B5CF6"), animate: showBars)
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatItem(label: "对话轮数", value: "\(score.stats.totalTurns)")
                StatItem(label: "学习时长", value: formatDuration(score.stats.sessionDuration))
                StatItem(label: "练习词汇", value: "\(score.stats.vocabularyPracticed)/\(score.stats.vocabularyTotal)")
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

    // MARK: - Vocabulary Details

    private var vocabularyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("词汇详情", systemImage: "textformat.abc")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            FlowLayout(spacing: 8) {
                ForEach(Array(score.vocabularyDetails.enumerated()), id: \.offset) { _, detail in
                    HStack(spacing: 4) {
                        Image(systemName: detail.practiced ? (detail.correct ? "checkmark.circle.fill" : "xmark.circle.fill") : "minus.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(detail.practiced ? (detail.correct ? Color(hex: "10B981") : Color(hex: "EF4444")) : Color(hex: "9CA3AF"))

                        Text(detail.word)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "1F2937"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(detail.practiced ? (detail.correct ? Color(hex: "ECFDF5") : Color(hex: "FEF2F2")) : Color(hex: "F9FAFB"))
                    )
                }
            }

            // Pronunciation notes
            let notedItems = score.vocabularyDetails.filter { $0.pronunciationNote != nil }
            if !notedItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(notedItems.enumerated()), id: \.offset) { _, detail in
                        if let note = detail.pronunciationNote {
                            Text("\(detail.word): \(note)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Sentence Details

    private var sentenceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("句型详情", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))

            ForEach(Array(score.sentenceDetails.enumerated()), id: \.offset) { _, detail in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: detail.practiced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(detail.practiced ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.pattern)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "1F2937"))

                        if let example = detail.exampleUsed {
                            Text("\"\(example)\"")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                                .italic()
                        }

                        if let feedback = detail.feedback {
                            Text(feedback)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        if !detail.practiced {
                            Text("未练习")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
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

// MARK: - Flow Layout (for vocabulary tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: width, height: maxHeight), positions)
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
