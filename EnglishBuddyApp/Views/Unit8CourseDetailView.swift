import SwiftUI

struct Unit8CourseDetailView: View {
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
            ChatView(lesson: unit8Lesson)
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

            Text("Unit 8")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit8Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit8Lesson) == .completed {
                        viewModel.uncompleteLesson(unit8Lesson)
                    } else {
                        viewModel.completeLesson(unit8Lesson, studyTime: 5)
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
            Text("At home")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("在家")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "F43F5E"), Color(hex: "FDA4AF")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F43F5E"))
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
                    .foregroundStyle(Color(hex: "F43F5E"))
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FFF1F2")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "房间", words: [
                        ("living room", "客厅"), ("bedroom", "卧室"), ("kitchen", "厨房"),
                        ("dining room", "餐厅"), ("bathroom", "浴室"), ("hall", "门厅")
                    ])

                    vocabCategoryCard(title: "家具和物品", words: [
                        ("bed", "床"), ("radio", "收音机"), ("bath", "浴缸"),
                        ("mirror", "镜子"), ("rug", "小地毯"), ("sofa", "沙发"),
                        ("floor", "地板"), ("armchair", "扶手椅"), ("lamp", "灯"),
                        ("phone", "电话"), ("painting", "画"), ("clock", "钟")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("flats", "公寓"), ("hut", "小屋"), ("detached house", "独立式住宅"),
                        ("stilt-house", "高脚屋"), ("houseboat", "船屋"), ("ranch", "大牧场")
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
                    .foregroundStyle(isExpanded ? Color(hex: "F43F5E") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "F43F5E"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "FFF1F2")))
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
                    .foregroundStyle(Color(hex: "F43F5E"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "询问物品位置") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Where's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" the book?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Where's the book?")

                            Spacer()

                            Text("书在哪里？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("It's")
                                .font(.system(size: 16)) +
                            Text(" on")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" the desk.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's on the desk.")

                            Spacer()

                            Text("在书桌上。")
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
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Where's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" the ball?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Where's the ball?")

                            Spacer()

                            Text("球在哪里？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("It's")
                                .font(.system(size: 16)) +
                            Text(" under")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" the chair.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's under the chair.")

                            Spacer()

                            Text("在椅子下面。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问某物是否在某处") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Is it")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" in the bag?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Is it in the bag?")

                            Spacer()

                            Text("它在包里吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("Yes, it ")
                                .font(.system(size: 16)) +
                            Text("is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ")
                                .font(.system(size: 16)) +
                            Text("isn't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, it is.")

                            Spacer()

                            Text("是的。/ 不是。")
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
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Is it")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" on the table?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Is it on the table?")

                            Spacer()

                            Text("它在桌子上吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("Yes, it ")
                                .font(.system(size: 16)) +
                            Text("is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ")
                                .font(.system(size: 16)) +
                            Text("isn't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, it is.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问某物在某处") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Where's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" the sofa?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Where's the sofa?")

                            Spacer()

                            Text("沙发在哪里？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("The sofa is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" in the living room.")
                                .font(.system(size: 16))

                            speakerButton(text: "The sofa is in the living room.")

                            Spacer()

                            Text("沙发在客厅里。")
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
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("Where's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" the fridge?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "Where's the fridge?")

                            Spacer()

                            Text("冰箱在哪里？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("The fridge is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" in the kitchen.")
                                .font(.system(size: 16))

                            speakerButton(text: "The fridge is in the kitchen.")

                            Spacer()

                            Text("冰箱在厨房里。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问某处有什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F43F5E")))

                            Text("What's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E")) +
                            Text(" in your bedroom?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F43F5E"))

                            speakerButton(text: "What's in your bedroom?")

                            Spacer()

                            Text("你卧室里有什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F43F5E"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF1F2")).overlay(Circle().stroke(Color(hex: "F43F5E"))))

                            Text("There's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" a bed, a desk and a chair.")
                                .font(.system(size: 16))

                            speakerButton(text: "There's a bed, a desk and a chair.")

                            Spacer()

                            Text("有一张床、一张书桌和一把椅子。")
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
                .foregroundStyle(Color(hex: "F43F5E"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "FFF1F2")))
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
                viewModel.startLesson(unit8Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "F43F5E"), Color(hex: "FDA4AF")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "F43F5E").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit8Lesson = Lesson(
    id: 8,
    title: "At home",
    subtitle: "在家",
    description: "学习房间名称和家具表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit8CourseDetailView(viewModel: CourseViewModel())
    }
}
