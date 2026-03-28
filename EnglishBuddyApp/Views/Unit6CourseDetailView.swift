import SwiftUI

struct Unit6CourseDetailView: View {
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
            ChatView(lesson: unit6Lesson)
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

            Text("Unit 6")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit6Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit6Lesson) == .completed {
                        viewModel.uncompleteLesson(unit6Lesson)
                    } else {
                        viewModel.completeLesson(unit6Lesson, studyTime: 5)
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
            Text("A day out")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("外出一天")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "67E8F9")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "06B6D4"))
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
                    .foregroundStyle(Color(hex: "06B6D4"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "ECFEFF")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "地点", words: [
                        ("zoo", "动物园"), ("park", "公园"), ("garden", "花园"),
                        ("bus stop", "公共汽车站"), ("shop", "商店")
                    ])

                    vocabCategoryCard(title:"交通工具", words: [
                        ("bus", "公交车"), ("car", "汽车"), ("lorry", "卡车"),
                        ("motorbike", "摩托车"), ("train", "火车")
                    ])

                    vocabCategoryCard(title: "动植物", words: [
                        ("tree", "树"), ("bear", "熊"), ("snake", "蛇"),
                        ("crocodile", "鳄鱼"), ("monkey", "猴子"), ("tiger", "老虎"),
                        ("elephant", "大象"), ("giraffe", "长颈鹿"), ("polar bear", "北极熊"),
                        ("lizard", "蜥蜴"), ("hippo", "河马"), ("zebra", "斑马")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("sea", "海洋"), ("jungle", "丛林"), ("Antarctica", "南极洲"),
                        ("rhino", "犀牛"), ("frog", "青蛙"), ("boa", "蟒蛇"),
                        ("penguin", "企鹅"), ("dolphin", "海豚")
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
                    .foregroundStyle(isExpanded ? Color(hex: "06B6D4") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "06B6D4"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "ECFEFF")))
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
                    .foregroundStyle(Color(hex: "06B6D4"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：用There is/are描述存在
                sentenceGroup(title: "用There is/are描述存在") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "✓",
                            parts: [.bold("There's"), .normal(" a car.")],
                            translation: "有一辆车。",
                            speakText: "There's a car."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("There "), .bold("isn't"), .normal(" a train.")],
                            translation: "没有火车。",
                            speakText: "There isn't a train."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("There "), .bold("are"), .normal(" two lorries.")],
                            translation: "有两辆卡车。",
                            speakText: "There are two lorries."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("There "), .bold("aren't"), .normal(" any shops.")],
                            translation: "没有任何商店。",
                            speakText: "There aren't any shops."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Are there"), .normal(" any animals?")],
                            translation: "有动物吗？",
                            speakText: "Are there any animals?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Yes, "), .bold("there are"), .normal(". / No, "), .bold("there aren't"), .normal(".")],
                            translation: "有。/ 没有。",
                            speakText: "Yes, there are. No, there aren't."
                        )
                    }
                }

                // 句型组2：用Let's提议一起行动
                sentenceGroup(title: "用Let's提议一起行动") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Let's play"), .normal(" a game.")],
                            translation: "我们来玩个游戏吧。",
                            speakText: "Let's play a game.",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("That's a good idea.")],
                            translation: "好主意。",
                            speakText: "That's a good idea."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Let's make"), .normal(" our game.")],
                            translation: "我们来做我们的游戏吧。",
                            speakText: "Let's make our game.",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("OK.")],
                            translation: "好的。",
                            speakText: "OK."
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
                    .foregroundStyle(isQuestion ? .white : Color(hex: "06B6D4"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "06B6D4") : Color(hex: "ECFEFF"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "06B6D4")))
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
        return result.foregroundColor(isQuestion ? Color(hex: "06B6D4") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "06B6D4"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "ECFEFF")))
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
                viewModel.startLesson(unit6Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "67E8F9")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit6Lesson = Lesson(
    id: 6,
    title: "A day out",
    subtitle: "外出一天",
    description: "学习地点、交通工具和野生动物",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit6CourseDetailView(viewModel: CourseViewModel())
    }
}
