import SwiftUI

struct CourseDetailView: View {
    let lesson: Lesson
    @Bindable var viewModel: CourseViewModel
    @State private var showingChat = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 24) {
                        bannerSection
                        goalsSection
                        vocabularySection
                        sentencesSection
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                bottomButton
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingChat) {
            ChatView(lesson: lesson)
        }
    }

    private var headerSection: some View {
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

            // Title
            Text(lesson.unitTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            // Complete button (always visible, toggles completion)
            CompleteButton(
                isCompleted: isLessonCompleted(),
                onToggle: { toggleCompletion() }
            )
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    private func toggleCompletion() {
        let currentStatus = viewModel.status(for: lesson)
        if currentStatus == .completed {
            // Mark as not completed
            viewModel.uncompleteLesson(lesson)
        } else {
            // Mark as completed
            viewModel.completeLesson(lesson, studyTime: 5)
        }
    }

    private func isLessonCompleted() -> Bool {
        return viewModel.status(for: lesson) == .completed
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.unitTitle).font(.system(size: 14)).foregroundStyle(.white.opacity(0.9))
            Text(lesson.title).font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
            Text(lesson.description).font(.system(size: 14)).foregroundStyle(.white.opacity(0.9)).padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "target").font(.system(size: 16)).foregroundStyle(Color(hex: "F97316"))
                Text("课程目标").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(alignment: .leading, spacing: 10) {
                GoalRow(text: "掌握本课核心词汇")
                GoalRow(text: "学会使用核心句型进行对话")
                GoalRow(text: "能与 xixi 进行简单英语交流")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
        }
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "textformat").font(.system(size: 16)).foregroundStyle(Color(hex: "F97316"))
                Text("核心词汇").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "1F2937"))
                Spacer()
                Text("\(lesson.vocabulary.count)个").font(.system(size: 14)).foregroundStyle(Color(hex: "9CA3AF"))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(lesson.vocabulary, id: \.word) { item in
                    VocabCard(item: item)
                }
            }
        }
    }

    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill").font(.system(size: 16)).foregroundStyle(Color(hex: "F97316"))
                Text("核心句型").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: "1F2937"))
                Spacer()
                Text("\(lesson.sentencePatterns.count)个").font(.system(size: 14)).foregroundStyle(Color(hex: "9CA3AF"))
            }

            LazyVStack(spacing: 12) {
                ForEach(Array(lesson.sentencePatterns.enumerated()), id: \.offset) { index, pattern in
                    SentenceCard(pattern: pattern)
                }
            }
        }
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "E5E7EB"))
            Button(action: onStartChat) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }

    private func onStartChat() {
        viewModel.startLesson(lesson)
        showingChat = true
    }
}

struct GoalRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text("•").font(.system(size: 16)).foregroundStyle(Color(hex: "F97316"))
            Text(text).font(.system(size: 14)).foregroundStyle(Color(hex: "4B5563"))
            Spacer()
        }
    }
}

struct VocabCard: View {
    let item: VocabularyItem
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 6) {
            // Word - centered, no phonetic
            Text(item.word)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Meaning - centered below
            Text(item.meaning)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: "FED7AA"), lineWidth: 2))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            TTSService.shared.speak(item.word)
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
    }
}

// MARK: - Complete Button
struct CompleteButton: View {
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: isCompleted ? "checkmark" : "circle")
                    .font(.system(size: 12, weight: .bold))
                Text("完成学习")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isCompleted ? Color(hex: "22C55E") : Color(hex: "9CA3AF"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(isCompleted ? Color(hex: "DCFCE7") : Color(hex: "F3F4F6")))
        }
        .buttonStyle(.plain)
    }
}

struct SentenceCard: View {
    let pattern: SentencePattern
    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.pattern)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "F97316"))
            }

            Spacer()

            Text(pattern.meaning)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6B7280"))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            TTSService.shared.speak(pattern.pattern)
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(lesson: Lesson.mockLessons[0], viewModel: CourseViewModel())
    }
}
