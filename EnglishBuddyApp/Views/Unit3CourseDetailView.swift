import SwiftUI

struct Unit3CourseDetailView: View {
    @Bindable var viewModel: CourseViewModel
    @State private var showingChat = false
    @State private var isVocabExpanded = true
    @Environment(\.dismiss) private var dismiss

    // Adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ZStack {
            Color(hex: "F8FAFC")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 24) {
                        bannerSection
                        vocabularySection
                        sentencesSection
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                    .padding(.top, 20)
                }

                bottomButton
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showingChat) {
            ChatView(lesson: unit3Lesson)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        let headerButtonSize = AdaptiveLayout.Dimensions.headerButtonSize(isCompact: isCompact)
        return HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: headerButtonSize, height: headerButtonSize)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            Text("Unit 3")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit3Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit3Lesson) == .completed {
                        viewModel.uncompleteLesson(unit3Lesson)
                    } else {
                        viewModel.completeLesson(unit3Lesson, studyTime: 5)
                    }
                }
            )
        }
        .frame(height: AdaptiveLayout.Dimensions.headerHeight(isCompact: isCompact))
        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Banner Section
    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fun on the farm")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("农场乐趣")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "84CC16"), Color(hex: "A3E635")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "84CC16"))
                Text("核心词汇")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVocabExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isVocabExpanded ? "收起" : "展开")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                        Image(systemName: isVocabExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 1, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "84CC16"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "F0FDF4")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "农场动物", words: [
                        ("cow", "奶牛"), ("donkey", "驴"), ("horse", "马"),
                        ("spider", "蜘蛛"), ("sheep", "绵羊"), ("goat", "山羊"),
                        ("cat", "猫"), ("chicken", "鸡"), ("dog", "狗"), ("duck", "鸭子")
                    ])

                    vocabCategoryCard(title: "形容词", words: [
                        ("small", "小的"), ("big", "大的"), ("long", "长的"),
                        ("short", "短的"), ("young", "年轻的"), ("old", "年长的"),
                        ("funny", "有趣的"), ("ugly", "丑陋的"), ("angry", "生气的"),
                        ("sad", "伤心的"), ("beautiful", "美丽的"), ("happy", "开心的")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("milk", "牛奶"), ("egg", "鸡蛋"), ("wool", "羊毛"), ("meat", "肉")
                    ], isExpanded: true)
                }
            }
        }
    }

    private func vocabCategoryCard(title: String, words: [(String, String)], isExpanded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .semibold))
                    .foregroundStyle(isExpanded ? Color(hex: "84CC16") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 2))
                        .foregroundStyle(Color(hex: "84CC16"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "F0FDF4")))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: AdaptiveLayout.Dimensions.vocabularyGridColumns(isCompact: isCompact)), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact)) {
                ForEach(words, id: \.0) { word, meaning in
                    VocabCard(item: VocabularyItem(word: word, meaning: meaning, phonetic: nil, category: title, image: nil))
                }
            }
        }
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .background(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    // MARK: - Sentences Section
    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "84CC16"))
                Text("核心句型")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：用形容词描述事物
                sentenceGroup(title: "用形容词描述事物") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("He's a "), .bold("nice"), .normal(" cat.")],
                            translation: "他是一只可爱的猫。",
                            speakText: "He's a nice cat."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("It isn't a "), .bold("big"), .normal(" spider.")],
                            translation: "它不是一只大蜘蛛。",
                            speakText: "It isn't a big spider."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("We're "), .bold("young"), .normal(" boys and girls.")],
                            translation: "我们是年轻的男孩和女孩。",
                            speakText: "We're young boys and girls."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("They aren't "), .bold("old"), .normal(" chickens.")],
                            translation: "它们不是老鸡。",
                            speakText: "They aren't old chickens."
                        )
                    }
                }

                // 句型组2：用has got / hasn't got描述特征
                sentenceGroup(title: "用has got描述特征") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("It's "), .bold("got"), .normal(" long ears.")],
                            translation: "它有长耳朵。",
                            speakText: "It's got long ears."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("It "), .bold("hasn't got"), .normal(" small feet.")],
                            translation: "它没有小脚。",
                            speakText: "It hasn't got small feet."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Has"), .normal(" it "), .bold("got"), .normal(" a long face?")],
                            translation: "它有长脸吗？",
                            speakText: "Has it got a long face?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Yes"), .normal(", it "), .bold("has"), .normal(". / "), .bold("No"), .normal(", it "), .bold("hasn't"), .normal(".")],
                            translation: "是的，它有。/ 不，它没有。",
                            speakText: "Yes, it has. No, it hasn't."
                        )
                    }
                }
            }
        }
    }

    // MARK: - Sentence Row Helper
    private enum TextPart {
        case normal(String)
        case bold(String)
    }

    private func sentenceRow(tag: String, parts: [TextPart], translation: String, speakText: String, isQuestion: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(tag)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isQuestion ? .white : Color(hex: "84CC16"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "84CC16") : Color(hex: "F0FDF4"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "84CC16")))
                    )

                buildText(parts: parts, isQuestion: isQuestion)

                speakerButton(text: speakText)

                Spacer()
            }

            Text(translation)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.leading, 30)
        }
    }

    private func buildText(parts: [TextPart], isQuestion: Bool) -> Text {
        var result = Text("")
        for part in parts {
            switch part {
            case .normal(let str):
                result = result + Text(str)
                    .font(.system(size: 16))
            case .bold(let str):
                result = result + Text(str)
                    .font(.system(size: 16, weight: .bold))
            }
        }
        return result.foregroundColor(isQuestion ? Color(hex: "84CC16") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "84CC16"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "F0FDF4")))
        }
        .buttonStyle(.plain)
    }

    private func sentenceGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            Text(title)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            content()
        }
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .background(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "E5E7EB"))
            Button(action: {
                viewModel.startLesson(unit3Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) - 2, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "84CC16"), Color(hex: "A3E635")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "84CC16").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit3Lesson = Lesson(
    id: 3,
    title: "Fun on the farm",
    subtitle: "农场乐趣",
    description: "学习农场动物和描述性形容词",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit3CourseDetailView(viewModel: CourseViewModel())
    }
}
