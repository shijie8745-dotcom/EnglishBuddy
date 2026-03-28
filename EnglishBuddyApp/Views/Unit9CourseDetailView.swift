import SwiftUI

struct Unit9CourseDetailView: View {
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
            ChatView(lesson: unit9Lesson)
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

            Text("Unit 9")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit9Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit9Lesson) == .completed {
                        viewModel.uncompleteLesson(unit9Lesson)
                    } else {
                        viewModel.completeLesson(unit9Lesson, studyTime: 5)
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
            Text("Happy holidays")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("假期快乐！")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "93C5FD")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "3B82F6"))
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
                    .foregroundStyle(Color(hex: "3B82F6"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "EFF6FF")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "服装", words: [
                        ("trousers", "裤子"), ("hat", "帽子"), ("sunglasses", "太阳镜"),
                        ("shirt", "衬衫"), ("short", "短裤"), ("boots", "靴子"),
                        ("jacket", "夹克"), ("skirt", "裙子"), ("baseball cap", "棒球帽"),
                        ("jeans", "牛仔裤"), ("dress", "连衣裙"), ("shoes", "鞋子"), ("T-shirt", "T恤衫")
                    ])

                    vocabCategoryCard(title: "户外", words: [
                        ("sun", "太阳"), ("fishing", "钓鱼"), ("jellyfish", "水母"),
                        ("fish", "鱼"), ("sea", "海洋"), ("boat", "小船"),
                        ("beach", "沙滩"), ("camera", "照相机"), ("sand", "沙子"), ("shell", "贝壳")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("shells", "贝壳"), ("snow", "雪"), ("flowers", "花"), ("tree", "树木"),
                        ("forest", "森林"), ("mountain", "山脉"), ("river", "河流"),
                        ("waterfall", "瀑布"), ("frog", "青蛙"), ("rocks", "岩石"), ("jellyfish", "水母")
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
                    .foregroundStyle(isExpanded ? Color(hex: "3B82F6") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "3B82F6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "EFF6FF")))
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
                    .foregroundStyle(Color(hex: "3B82F6"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：祈使句指令
                sentenceGroup(title: "祈使句指令") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Look at"), .normal(" this T-shirt.")],
                            translation: "看这件T恤。",
                            speakText: "Look at this T-shirt."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Point to"), .normal(" that dress there.")],
                            translation: "指向那边那条裙子。",
                            speakText: "Point to that dress there."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Pick up"), .normal(" these socks.")],
                            translation: "捡起这些袜子。",
                            speakText: "Pick up these socks."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Clean"), .normal(" those shoes.")],
                            translation: "擦干净那些鞋子。",
                            speakText: "Clean those shoes."
                        )
                    }
                }

                // 句型组2：表达喜好和附和
                sentenceGroup(title: "表达喜好和附和") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "A",
                            parts: [.normal("I "), .bold("like"), .normal(" flying my kite.")],
                            translation: "我喜欢放风筝。",
                            speakText: "I like flying my kite."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("So do I"), .normal(".")],
                            translation: "我也是。",
                            speakText: "So do I."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("I "), .bold("enjoy"), .normal(" taking photos.")],
                            translation: "我喜欢拍照。",
                            speakText: "I enjoy taking photos."
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.bold("Me too"), .normal(".")],
                            translation: "我也是。",
                            speakText: "Me too."
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
                    .foregroundStyle(isQuestion ? .white : Color(hex: "3B82F6"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "3B82F6") : Color(hex: "EFF6FF"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "3B82F6")))
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
        return result.foregroundColor(isQuestion ? Color(hex: "3B82F6") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "3B82F6"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "EFF6FF")))
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
                viewModel.startLesson(unit9Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "3B82F6"), Color(hex: "93C5FD")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "3B82F6").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit9Lesson = Lesson(
    id: 9,
    title: "Happy holidays",
    subtitle: "假期快乐！",
    description: "学习天气、季节和感受表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit9CourseDetailView(viewModel: CourseViewModel())
    }
}
