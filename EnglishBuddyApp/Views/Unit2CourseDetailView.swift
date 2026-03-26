import SwiftUI

struct Unit2CourseDetailView: View {
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
            ChatView(lesson: unit2Lesson)
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

            Text("Unit 2")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit2Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit2Lesson) == .completed {
                        viewModel.uncompleteLesson(unit2Lesson)
                    } else {
                        viewModel.completeLesson(unit2Lesson, studyTime: 5)
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
            Text("All about us")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("关于我们")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "EC4899"))
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
                    .foregroundStyle(Color(hex: "EC4899"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FDF2F8")))
                }
                .buttonStyle(.plain)
            }

            // 词汇内容（可收起）
            if isVocabExpanded {
                VStack(spacing: 12) {
                    // 家庭成员
                    vocabCategoryCard(title: "家庭成员", words: [
                        ("family", "家人"), ("mum", "妈妈"), ("dad", "爸爸"),
                        ("sister", "姐妹"), ("brother", "兄弟"), ("baby", "婴儿/宝宝")
                    ])

                    // 身体部位
                    vocabCategoryCard(title: "身体部位", words: [
                        ("head", "头"), ("eyes", "眼睛"), ("ears", "耳朵"),
                        ("nose", "鼻子"), ("mouth", "嘴巴"), ("hair", "头发")
                    ])

                    // 外貌颜色
                    vocabCategoryCard(title: "外貌颜色", words: [
                        ("brown", "棕色"), ("green", "绿色"), ("blue", "蓝色")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("see", "看"), ("hear", "听"), ("smell", "闻"), ("taste", "尝"), ("touch", "触摸")
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
                    .foregroundStyle(isExpanded ? Color(hex: "EC4899") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "EC4899"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "FDF2F8")))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: AdaptiveLayout.Dimensions.vocabularyGridColumns(isCompact: isCompact)), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact)) {
                ForEach(words, id: \.0) { word, meaning in
                    VocabCard(item: VocabularyItem(word: word, meaning: meaning, phonetic: nil, category: title, image: nil))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    // MARK: - Sentences Section
    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EC4899"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：Who is she/he?
                sentenceGroup(title: "询问人物身份") {
                    VStack(spacing: 10) {
                        // 女性
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Who's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" she?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Who's she?")

                            Spacer()

                            Text("她是谁？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("She's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" my mum.")
                                .font(.system(size: 16))

                            speakerButton(text: "She's my mum.")

                            Spacer()

                            Text("她是我妈妈。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        // 男性
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Who's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" he?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Who's he?")

                            Spacer()

                            Text("他是谁？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("He's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" my dad.")
                                .font(.system(size: 16))

                            speakerButton(text: "He's my dad.")

                            Spacer()

                            Text("他是我爸爸。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                // 句型组2：Is he/she your...?
                sentenceGroup(title: "确认人物关系") {
                    VStack(spacing: 10) {
                        // 一般疑问句
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Is she")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" your sister?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Is she your sister?")

                            Spacer()

                            Text("她是你姐妹吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("Yes, she ").font(.system(size: 16)) +
                            Text("is").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, she ").font(.system(size: 16)) +
                            Text("isn't").font(.system(size: 16, weight: .bold)) +
                            Text(".").font(.system(size: 16))

                            speakerButton(text: "Yes, she is.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        // 复数形式
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Are they")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" your friends?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Are they your friends?")

                            Spacer()

                            Text("他们是你的朋友吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("Yes, they ").font(.system(size: 16)) +
                            Text("are").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, they ").font(.system(size: 16)) +
                            Text("aren't").font(.system(size: 16, weight: .bold)) +
                            Text(".").font(.system(size: 16))

                            speakerButton(text: "Yes, they are.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                // 句型组3：Have you got...?
                sentenceGroup(title: "询问拥有") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Have you got")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" a brother?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Have you got a brother?")

                            Spacer()

                            Text("你有兄弟吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("Yes, I ").font(.system(size: 16)) +
                            Text("have").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I ").font(.system(size: 16)) +
                            Text("haven't").font(.system(size: 16, weight: .bold)) +
                            Text(".").font(.system(size: 16))

                            speakerButton(text: "Yes, I have.")

                            Spacer()

                            Text("是的，我有。/ 不，我没有。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        // 复数形式
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("Have you got")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" big eyes?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "Have you got big eyes?")

                            Spacer()

                            Text("你有大眼睛吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("Yes, I ").font(.system(size: 16)) +
                            Text("have").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I ").font(.system(size: 16)) +
                            Text("haven't").font(.system(size: 16, weight: .bold)) +
                            Text(".").font(.system(size: 16))

                            speakerButton(text: "Yes, I have.")

                            Spacer()

                            Text("是的，我有。/ 不，我没有。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                // 句型组4：What colour...have you got?
                sentenceGroup(title: "询问颜色属性") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("What colour")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" eyes have you got?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "What colour eyes have you got?")

                            Spacer()

                            Text("你眼睛是什么颜色的？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("I've got")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" brown eyes.")
                                .font(.system(size: 16))

                            speakerButton(text: "I've got brown eyes.")

                            Spacer()

                            Text("我有棕色眼睛。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        // 头发
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EC4899")))

                            Text("What colour")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899")) +
                            Text(" hair have you got?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EC4899"))

                            speakerButton(text: "What colour hair have you got?")

                            Spacer()

                            Text("你头发是什么颜色的？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EC4899"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FDF2F8")).overlay(Circle().stroke(Color(hex: "EC4899"))))

                            Text("I've got")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" black hair.")
                                .font(.system(size: 16))

                            speakerButton(text: "I've got black hair.")

                            Spacer()

                            Text("我有黑色头发。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
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
                .foregroundStyle(Color(hex: "EC4899"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "FDF2F8")))
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
                viewModel.startLesson(unit2Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "EC4899").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

// MARK: - Unit 2 Lesson Data
private let unit2Lesson = Lesson(
    id: 2,
    title: "All about us",
    subtitle: "关于我们",
    description: "学习家庭成员、身体部位和颜色描述",
    vocabulary: [],
    sentencePatterns: []
)

// MARK: - Preview
#Preview {
    NavigationStack {
        Unit2CourseDetailView(viewModel: CourseViewModel())
    }
}
