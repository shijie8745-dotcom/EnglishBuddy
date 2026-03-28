import SwiftUI

struct Unit7CourseDetailView: View {
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
            ChatView(lesson: unit7Lesson)
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

            Text("Unit 7")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit7Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit7Lesson) == .completed {
                        viewModel.uncompleteLesson(unit7Lesson)
                    } else {
                        viewModel.completeLesson(unit7Lesson, studyTime: 5)
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
            Text("Let's play")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("让我们一起玩！")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "6EE7B7")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "10B981"))
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
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "ECFDF5")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "活动", words: [
                        ("play football", "足球"), ("play basketball", "篮球"), ("play tennis", "网球"),
                        ("play badminton", "羽毛球"), ("play baseball", "棒球"), ("play hockey", "曲棍球"),
                        ("play the guitar", "吉他"), ("play the piano", "钢琴"), ("ride a bike", "自行车"),
                        ("ride the skateboard", "滑板"), ("watch television", "电视")
                    ])

                    vocabCategoryCard(title: "动词", words: [
                        ("swim", "游泳"), ("run", "跑步"), ("throw", "扔"),
                        ("catch", "接"), ("kick", "踢"), ("hit", "击打"),
                        ("jump", "跳")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("stretch your arms", "伸直手臂"), ("stretch your legs", "伸直腿"), ("stretch your body", "伸直身体")
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
                    .foregroundStyle(isExpanded ? Color(hex: "10B981") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "10B981"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "ECFDF5")))
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
                    .foregroundStyle(Color(hex: "10B981"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：现在进行时
                sentenceGroup(title: "用现在进行时描述正在做的事") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.normal("What "), .bold("are"), .normal(" you do"), .bold("ing"), .normal("?")],
                            translation: "你在做什么？",
                            speakText: "What are you doing?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("I'm rid"), .bold("ing"), .normal(" a horse.")],
                            translation: "我在骑马。",
                            speakText: "I'm riding a horse."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.normal("What"), .bold("'s"), .normal(" she do"), .bold("ing"), .normal("?")],
                            translation: "她在做什么？",
                            speakText: "What's she doing?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("She"), .bold("'s"), .normal(" swimm"), .bold("ing"), .normal(".")],
                            translation: "她在游泳。",
                            speakText: "She's swimming."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Are"), .normal(" they clean"), .bold("ing"), .normal(" the car?")],
                            translation: "他们在洗车吗？",
                            speakText: "Are they cleaning the car?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Yes, they "), .bold("are"), .normal(". / No, they "), .bold("aren't"), .normal(".")],
                            translation: "是的，他们在。/ 不，他们没有。",
                            speakText: "Yes, they are. No, they aren't."
                        )
                    }
                }

                // 句型组2：用can表达许可
                sentenceGroup(title: "用can表达许可") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Can"), .normal(" we "), .bold("play"), .normal(" tennis?")],
                            translation: "我们可以打网球吗？",
                            speakText: "Can we play tennis?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Yes, you "), .bold("can"), .normal(", but you "), .bold("can't play"), .normal(" here.")],
                            translation: "可以，但你们不能在这里打。",
                            speakText: "Yes, you can, but you can't play here."
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
                    .foregroundStyle(isQuestion ? .white : Color(hex: "10B981"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "10B981") : Color(hex: "ECFDF5"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "10B981")))
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
        return result.foregroundColor(isQuestion ? Color(hex: "10B981") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "10B981"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "ECFDF5")))
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
                viewModel.startLesson(unit7Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "6EE7B7")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit7Lesson = Lesson(
    id: 7,
    title: "Let's play",
    subtitle: "让我们一起玩！",
    description: "学习运动项目和动作表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit7CourseDetailView(viewModel: CourseViewModel())
    }
}
