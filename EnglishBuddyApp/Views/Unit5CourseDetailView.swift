import SwiftUI

struct Unit5CourseDetailView: View {
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
            ChatView(lesson: unit5Lesson)
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

            Text("Unit 5")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit5Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit5Lesson) == .completed {
                        viewModel.uncompleteLesson(unit5Lesson)
                    } else {
                        viewModel.completeLesson(unit5Lesson, studyTime: 5)
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
            Text("Happy birthday")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("生日快乐！")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "8B5CF6"))
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
                    .foregroundStyle(Color(hex: "8B5CF6"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "F5F3FF")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "玩具", words: [
                        ("ball", "球"), ("bike", "自行车"), ("kite", "风筝"),
                        ("robot", "机器人"), ("car", "汽车"), ("doll", "洋娃娃"),
                        ("plane", "飞机"), ("house", "房子"), ("teddy", "泰迪熊"),
                        ("computer", "电脑"), ("mouse", "鼠标"), ("balloon", "气球"),
                        ("keyboard", "键盘"), ("radio", "收音机"), ("board game", "桌游"),
                        ("helicopter", "直升机"), ("ship", "轮船"), ("box", "盒子")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("circle", "圆形"), ("square", "正方形"), ("triangle", "三角形"),
                        ("rectangle", "长方形"), ("star", "星形")
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
                    .foregroundStyle(isExpanded ? Color(hex: "8B5CF6") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 2))
                        .foregroundStyle(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "F5F3FF")))
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
                    .foregroundStyle(Color(hex: "8B5CF6"))
                Text("核心句型")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "询问物品归属") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("Whose")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" ball is this?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "Whose ball is this?")

                            Spacer()

                            Text("这是谁的球？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" my ball.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's my ball.")

                            Spacer()

                            Text("这是我的球。")
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
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("Whose")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" doll is that?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "Whose doll is that?")

                            Spacer()

                            Text("那是谁的玩偶？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" her doll.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's her doll.")

                            Spacer()

                            Text("那是她的玩偶。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问想要什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("What do you want?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "What do you want?")

                            Spacer()

                            Text("你想要什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("I want")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" a toy car.")
                                .font(.system(size: 16))

                            speakerButton(text: "I want a toy car.")

                            Spacer()

                            Text("我想要一辆玩具车。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问是否想要某物") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("Do you want")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" a scooter?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "Do you want a scooter?")

                            Spacer()

                            Text("你想要滑板车吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("Yes")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(", please. / ")
                                .font(.system(size: 16)) +
                            Text("No")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(", thank you.")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, please.")

                            Spacer()

                            Text("好的。/ 不用了，谢谢。")
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
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("Do you want")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" a robot?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "Do you want a robot?")

                            Spacer()

                            Text("你想要机器人吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("Yes")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(", please. / ")
                                .font(.system(size: 16)) +
                            Text("No")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(", thank you.")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, please.")

                            Spacer()

                            Text("好的。/ 不用了，谢谢。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问生日") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("When's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" your birthday?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "When's your birthday?")

                            Spacer()

                            Text("你的生日是什么时候？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" in March.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's in March.")

                            Spacer()

                            Text("在三月。")
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
                                .background(Circle().fill(Color(hex: "8B5CF6")))

                            Text("How old")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6")) +
                            Text(" are you?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "8B5CF6"))

                            speakerButton(text: "How old are you?")

                            Spacer()

                            Text("你几岁了？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F5F3FF")).overlay(Circle().stroke(Color(hex: "8B5CF6"))))

                            Text("I'm")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" eight.")
                                .font(.system(size: 16))

                            speakerButton(text: "I'm eight.")

                            Spacer()

                            Text("我八岁了。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }
            }
        }
    }

    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        let buttonSize = AdaptiveLayout.Dimensions.speakerButtonSize(isCompact: isCompact)
        return Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "8B5CF6"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "F5F3FF")))
        }
        .buttonStyle(.plain)
    }

    private func sentenceGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                viewModel.startLesson(unit5Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) - 2, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit5Lesson = Lesson(
    id: 5,
    title: "Happy birthday",
    subtitle: "生日快乐！",
    description: "学习月份和玩具表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit5CourseDetailView(viewModel: CourseViewModel())
    }
}
