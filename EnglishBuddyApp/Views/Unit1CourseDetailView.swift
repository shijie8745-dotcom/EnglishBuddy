import SwiftUI

struct Unit1CourseDetailView: View {
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
            ChatView(lesson: unit1Lesson)
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

            Text("Unit 1")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit1Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit1Lesson) == .completed {
                        viewModel.uncompleteLesson(unit1Lesson)
                    } else {
                        viewModel.completeLesson(unit1Lesson, studyTime: 5)
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
            Text("Our New School")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("我们的新学校")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("核心词汇")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                // 收起/展开按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVocabExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isVocabExpanded ? "收起" : "展开")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 1))
                        Image(systemName: isVocabExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact), weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "F97316"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FFF7ED")))
                }
                .buttonStyle(.plain)
            }

            // 词汇内容（可收起）
            if isVocabExpanded {
                VStack(spacing: 12) {
                    // 文具类
                    vocabCategoryCard(title: "文具类", words: [
                        ("pencil", "铅笔"), ("rubber", "橡皮"), ("crayon", "蜡笔"),
                        ("pen", "钢笔"), ("pencil case", "文具盒"), ("ruler", "尺子"),
                        ("book", "书"), ("bag", "书包")
                    ])

                    // 教室设施
                    vocabCategoryCard(title: "教室设施", words: [
                        ("desk", "书桌"), ("chair", "椅子"), ("bookcase", "书柜"),
                        ("cupboard", "橱柜"), ("door", "门"), ("window", "窗户"),
                        ("wall", "墙"), ("board", "黑板"), ("playground", "游戏场"),
                        ("paper", "纸")
                    ])

                    // 人物与场所
                    vocabCategoryCard(title: "人物与场所", words: [
                        ("teacher", "老师"), ("classroom", "教室")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("help", "帮助"), ("listen", "倾听"), ("share", "分享"), ("work together", "合作")
                    ], isExpanded: true)
                }
            }
        }
    }

    private func vocabCategoryCard(title: String, words: [(String, String)], isExpanded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isExpanded ? Color(hex: "F97316") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "F97316"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "FFF7ED")))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: AdaptiveLayout.Dimensions.vocabularyGridColumns(isCompact: isCompact)), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact)) {
                ForEach(words, id: \.0) { word, meaning in
                    VocabCard(item: VocabularyItem(word: word, meaning: meaning, phonetic: nil, category: title, image: nil))
                }
            }
        }
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    // MARK: - Sentences Section
    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：用介词描述物品位置
                sentenceGroup(title: "用介词描述物品位置") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Where's"), .normal(" the crayon?")],
                            translation: "蜡笔在哪里？",
                            speakText: "Where's the crayon?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("It's "), .bold("on"), .normal(" the desk.")],
                            translation: "在书桌上。",
                            speakText: "It's on the desk."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("It's "), .bold("in"), .normal(" the pencil case.")],
                            translation: "在文具盒里。",
                            speakText: "It's in the pencil case."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("It's "), .bold("under"), .normal(" the book.")],
                            translation: "在书下面。",
                            speakText: "It's under the book."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("It's "), .bold("next to"), .normal(" the rubber.")],
                            translation: "在橡皮旁边。",
                            speakText: "It's next to the rubber."
                        )
                    }
                }

                // 句型组2：询问单数和复数物品
                sentenceGroup(title: "询问单数和复数物品") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.normal("What's "), .bold("this"), .normal("?")],
                            translation: "这是什么？",
                            speakText: "What's this?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("It's"), .normal(" a window.")],
                            translation: "它是一扇窗户。",
                            speakText: "It's a window."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.normal("What "), .bold("are these"), .normal("?")],
                            translation: "这些是什么？",
                            speakText: "What are these?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("They're"), .normal(" windows.")],
                            translation: "它们是窗户。",
                            speakText: "They're windows."
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
                // Q/A 标签
                Text(tag)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isQuestion ? .white : Color(hex: "F97316"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "F97316") : Color(hex: "FFF7ED"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "F97316")))
                    )

                // 英文内容
                buildText(parts: parts, isQuestion: isQuestion)

                // 朗读按钮
                speakerButton(text: speakText)

                Spacer()
            }

            // 中文翻译（紧跟英文下方，左侧对齐到英文位置）
            Text(translation)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.leading, 30) // 22(标签) + 8(间距)
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
        return result.foregroundColor(isQuestion ? Color(hex: "F97316") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "F97316"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "FFF7ED")))
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

    // MARK: - Bottom Button
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "E5E7EB"))
            Button(action: {
                viewModel.startLesson(unit1Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

// MARK: - Unit 1 Lesson Data
private let unit1Lesson = Lesson(
    id: 1,
    title: "Our New School",
    subtitle: "我们的新学校",
    description: "学习学校用品、教室物品和方位表达",
    vocabulary: [],
    sentencePatterns: []
)

// MARK: - Preview
#Preview {
    NavigationStack {
        Unit1CourseDetailView(viewModel: CourseViewModel())
    }
}
