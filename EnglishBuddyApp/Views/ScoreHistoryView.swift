import SwiftUI

struct ScoreHistoryView: View {
    @State private var scores: [ScoreResult] = []
    @State private var selectedScore: ScoreResult?
    @State private var showDetail = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        VStack(spacing: 0) {
            if scores.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 最近一次评分（展开显示）
                        if let latest = scores.first {
                            latestScoreCard(latest)
                        }

                        // 历史记录
                        if scores.count > 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("历史记录")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "1F2937"))

                                ForEach(Array(scores.dropFirst())) { score in
                                    historyRow(score)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color(hex: "FEF7ED").ignoresSafeArea())
        .navigationTitle("评分记录")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scores = ScoreHistoryStore.shared.loadAllScores()
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let score = selectedScore {
                ScoreResultView(score: score, onDismiss: {
                    showDetail = false
                })
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "star.bubble")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "D1D5DB"))

            Text("还没有评分记录")
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "9CA3AF"))

            Text("在对话练习中点击评分按钮开始评分")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "D1D5DB"))

            Spacer()
        }
    }

    // MARK: - Latest Score Card

    private func latestScoreCard(_ score: ScoreResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "F59E0B"))

                Text("最近一次评分")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                Text(formatDate(score.timestamp))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color(hex: "F97316").opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.overallScore) / 100.0)
                        .stroke(Color(hex: "F97316"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(score.overallScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "F97316"))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(score.lessonTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "1F2937"))
                        .lineLimit(1)

                    // Stars
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < score.starRating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundStyle(i < score.starRating ? Color(hex: "F59E0B") : Color(hex: "D1D5DB"))
                        }
                    }

                    // Dimension scores summary
                    HStack(spacing: 8) {
                        miniScore("词汇", score.vocabularyScore)
                        miniScore("语法", score.grammarScore)
                        miniScore("发音", score.pronunciationScore)
                        miniScore("流利", score.fluencyScore)
                    }
                }

                Spacer()
            }

            // Encouragement
            Text(score.encouragement)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "F97316"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FFF7ED"))
                )

            // Detail button
            Button(action: {
                selectedScore = score
                showDetail = true
            }) {
                Text("查看详情")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "F97316"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "F97316"), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - History Row

    private func historyRow(_ score: ScoreResult) -> some View {
        Button(action: {
            selectedScore = score
            showDetail = true
        }) {
            HStack(spacing: 12) {
                // Score badge
                Text("\(score.overallScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(score.lessonTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "1F2937"))
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < score.starRating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(i < score.starRating ? Color(hex: "F59E0B") : Color(hex: "D1D5DB"))
                        }

                        Text(formatDate(score.timestamp))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                            .padding(.leading, 4)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func miniScore(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "1F2937"))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "M月d日"
        }
        return formatter.string(from: date)
    }
}
