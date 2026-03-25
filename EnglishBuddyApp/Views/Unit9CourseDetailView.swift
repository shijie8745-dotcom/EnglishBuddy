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
                    vocabCategoryCard(title: "天气类", words: [
                        ("weather", "天气"), ("sunny", "晴朗的"), ("cloudy", "多云的"),
                        ("rainy", "下雨的"), ("snowy", "下雪的"), ("windy", "有风的"),
                        (".hot", "热的"), ("cold", "冷的"), ("warm", "温暖的"),
                        ("cool", "凉爽的")
                    ])

                    vocabCategoryCard(title: "季节类", words: [
                        ("season", "季节"), ("spring", "春天"), ("summer", "夏天"),
                        ("autumn", "秋天"), ("_.winter", "冬天"), ("year", "年")
                    ])

                    vocabCategoryCard(title: "活动类", words: [
                        ("holiday", "假期"), ("vacation", "假期"), ("travel", "旅行"),
                        ("visit", "参观"), ("play", "玩耍"), ("swim", "游泳"),
                        ("ski", "滑雪"), ("climb", "爬山"), ("camp", "露营")
                    ])

                    vocabCategoryCard(title: "感受与情绪", words: [
                        ("feel", "感觉"), ("happy", "开心的"), ("sad", "难过的"),
                        ("tired", "累的"), ("excited", "兴奋的"), ("hungry", "饿的"),
                        ("thirsty", "渴的"), ("hot", "热的"), ("cold", "冷的")
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
                sentenceGroup(title: "询问天气") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("What's the weather like?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "What's the weather like?")

                            Spacer()

                            Text("天气怎么样？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" sunny.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's sunny.")

                            Spacer()

                            Text("晴天。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("What's the weather like today?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "What's the weather like today?")

                            Spacer()

                            Text("今天天气怎么样？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" rainy.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's rainy.")

                            Spacer()

                            Text("下雨。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问季节") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("What season")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6")) +
                            Text(" is it?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "What season is it?")

                            Spacer()

                            Text("现在是什么季节？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" summer.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's summer.")

                            Spacer()

                            Text("是夏天。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("What season")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6")) +
                            Text(" do you like?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "What season do you like?")

                            Spacer()

                            Text("你喜欢什么季节？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("I like")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" spring.")
                                .font(.system(size: 16))

                            speakerButton(text: "I like spring.")

                            Spacer()

                            Text("我喜欢春天。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问感受") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("How are you feeling?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "How are you feeling?")

                            Spacer()

                            Text("你感觉怎么样？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("I'm")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" happy.")
                                .font(.system(size: 16))

                            speakerButton(text: "I'm happy.")

                            Spacer()

                            Text("我很开心。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "3B82F6")))

                            Text("Are you")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6")) +
                            Text(" tired?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "Are you tired?")

                            Spacer()

                            Text("你累吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EFF6FF")).overlay(Circle().stroke(Color(hex: "3B82F6"))))

                            Text("Yes, I ") +
                            Text("am")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I") +
                            Text("'m")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" ") +
                            Text("not")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")

                            speakerButton(text: "Yes, I am.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "表达喜好") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("I like")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6")) +
                            Text(" swimming.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "I like swimming.")

                            Spacer()

                            Text("我喜欢游泳。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("I enjoy")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "3B82F6")) +
                            Text(" hiking.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "3B82F6"))

                            speakerButton(text: "I enjoy hiking.")

                            Spacer()

                            Text("我喜欢远足。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                }
            }
        }
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
