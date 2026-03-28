import SwiftUI

struct Unit4CourseDetailView: View {
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
            ChatView(lesson: unit4Lesson)
        }
    }

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

            Text("Unit 4")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit4Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit4Lesson) == .completed {
                        viewModel.uncompleteLesson(unit4Lesson)
                    } else {
                        viewModel.completeLesson(unit4Lesson, studyTime: 5)
                    }
                }
            )
        }
        .frame(height: AdaptiveLayout.Dimensions.headerHeight(isCompact: isCompact))
        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food with friends")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("与朋友分享食物")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "EAB308"), Color(hex: "FDE047")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "EAB308"))
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
                    .foregroundStyle(Color(hex: "EAB308"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FEF9C3")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "食物", words: [
                        ("chicken", "鸡肉"), ("chocolate", "巧克力"), ("cake", "蛋糕"),
                        ("bread", "面包"), ("bananas", "香蕉"), ("mangoes", "芒果"),
                        ("burgers", "汉堡"), ("salad", "沙拉"), ("fruit", "水果"),
                        ("apples", "苹果"), ("oranges", "橙子"), ("grapes", "葡萄"),
                        ("meat", "肉类"), ("meatballs", "肉丸"), ("sausages", "香肠"),
                        ("beans", "豆子"), ("lemonade", "柠檬水"), ("water", "水"), ("juice", "果汁")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("carrots", "胡萝卜"), ("eggs", "鸡蛋"), ("onions", "洋葱"),
                        ("tomatoes", "西红柿"), ("cheese", "奶酪"), ("pasta", "意大利面"),
                        ("potatoes", "土豆"), ("rice", "米饭"), ("meat", "肉类")
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
                    .foregroundStyle(isExpanded ? Color(hex: "EAB308") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 2))
                        .foregroundStyle(Color(hex: "EAB308"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "FEF9C3")))
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

    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "EAB308"))
                Text("核心句型")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：用like表达喜好
                sentenceGroup(title: "用like表达喜好") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("I "), .bold("like"), .normal(" chocolate.")],
                            translation: "我喜欢巧克力。",
                            speakText: "I like chocolate."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("I "), .bold("don't like"), .normal(" books.")],
                            translation: "我不喜欢书。",
                            speakText: "I don't like books."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "✓",
                            parts: [.normal("Harry "), .bold("likes"), .normal(" mangoes.")],
                            translation: "Harry喜欢芒果。",
                            speakText: "Harry likes mangoes."
                        )

                        sentenceRow(
                            tag: "✗",
                            parts: [.normal("Harry "), .bold("doesn't like"), .normal(" chocolate.")],
                            translation: "Harry不喜欢巧克力。",
                            speakText: "Harry doesn't like chocolate."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Do"), .normal(" you "), .bold("like"), .normal(" chocolate?")],
                            translation: "你喜欢巧克力吗？",
                            speakText: "Do you like chocolate?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Yes, I "), .bold("do"), .normal(". / No, I "), .bold("don't"), .normal(".")],
                            translation: "是的，我喜欢。/ 不，我不喜欢。",
                            speakText: "Yes, I do. No, I don't."
                        )
                    }
                }

                // 句型组2：礼貌请求和询问意愿
                sentenceGroup(title: "礼貌请求和询问意愿") {
                    VStack(spacing: 10) {
                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Can I have"), .normal(" some chocolate, "), .bold("please"), .normal("?")],
                            translation: "我可以要一些巧克力吗？",
                            speakText: "Can I have some chocolate, please?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Here you are.")],
                            translation: "给你。",
                            speakText: "Here you are."
                        )

                        Divider().padding(.vertical, 2)

                        sentenceRow(
                            tag: "Q",
                            parts: [.bold("Would you like"), .normal(" some ice cream?")],
                            translation: "你想要一些冰淇淋吗？",
                            speakText: "Would you like some ice cream?",
                            isQuestion: true
                        )

                        sentenceRow(
                            tag: "A",
                            parts: [.normal("Yes, "), .bold("please"), .normal(". / No, "), .bold("thank you"), .normal(".")],
                            translation: "好的，谢谢。/ 不用了，谢谢。",
                            speakText: "Yes, please. No, thank you."
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
                    .foregroundStyle(isQuestion ? .white : Color(hex: "EAB308"))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(isQuestion ? Color(hex: "EAB308") : Color(hex: "FEF9C3"))
                            .overlay(isQuestion ? nil : Circle().stroke(Color(hex: "EAB308")))
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
        return result.foregroundColor(isQuestion ? Color(hex: "EAB308") : Color(hex: "1F2937"))
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "EAB308"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "FEF9C3")))
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
                viewModel.startLesson(unit4Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) - 2, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "EAB308"), Color(hex: "FDE047")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "EAB308").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit4Lesson = Lesson(
    id: 4,
    title: "Food with friends",
    subtitle: "与朋友分享食物",
    description: "学习水果、食物和饮料的表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit4CourseDetailView(viewModel: CourseViewModel())
    }
}
