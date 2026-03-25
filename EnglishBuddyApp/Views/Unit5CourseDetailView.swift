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
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            Text("Unit 5")
                .font(.system(size: 20, weight: .bold))
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
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Happy birthday")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("生日快乐！")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "8B5CF6"))
                Text("核心词汇")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVocabExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isVocabExpanded ? "收起" : "展开")
                            .font(.system(size: 13))
                        Image(systemName: isVocabExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
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
                    vocabCategoryCard(title: "月份", words: [
                        ("January", "一月"), ("February", "二月"), ("March", "三月"),
                        ("April", "四月"), ("May", "五月"), ("June", "六月"),
                        ("July", "七月"), ("August", "八月"), ("September", "九月"),
                        ("October", "十月"), ("November", "十一月"), ("December", "十二月")
                    ])

                    vocabCategoryCard(title: "玩具类", words: [
                        ("ball", "球"), ("doll", "玩偶"), ("scooter", "滑板车"),
                        ("robot", "机器人"), ("skateboard", "滑板"), ("toy car", "玩具车"),
                        ("toy plane", "玩具飞机"), ("toy boat", "玩具船"), ("teddy bear", "泰迪熊")
                    ])

                    vocabCategoryCard(title:"数字与生日", words: [
                        ("birthday", "生日"), ("present", "礼物"), ("card", "卡片"),
                        ("party", "聚会"), ("candle", "蜡烛"), ("cake", "蛋糕"),
                        ("first", "第一"), ("second", "第二"), ("third", "第三"),
                        ("How old", "多少岁"), ("When", "什么时候")
                    ])

                    vocabCategoryCard(title: "其他", words: [
                        ("toy", "玩具"), (" zoo", "动物园"), ("love", "爱"),
                        ("fun", "乐趣"), ("weather", "天气"), ("rainy", "下雨的")
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
                    .foregroundStyle(isExpanded ? Color(hex: "8B5CF6") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
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
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "8B5CF6"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
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
        Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "8B5CF6"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "F5F3FF")))
        }
        .buttonStyle(.plain)
    }

    private func sentenceGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white).shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2))
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "E5E7EB"))
            Button(action: {
                viewModel.startLesson(unit5Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, 16)
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
