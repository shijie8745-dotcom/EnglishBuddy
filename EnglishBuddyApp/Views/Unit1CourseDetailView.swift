import SwiftUI

struct Unit1CourseDetailView: View {
    @Bindable var viewModel: CourseViewModel
    @State private var showingChat = false
    @State private var isVocabExpanded = true
    @Environment(\.dismiss) private var dismiss

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
                    .padding(.horizontal, 20)
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
        HStack(spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "F3F4F6")))
            }

            Spacer()

            Text("Unit 1")
                .font(.system(size: 20, weight: .bold))
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
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Banner Section
    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Our New School")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("我们的新学校")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("核心词汇")
                    .font(.system(size: 16, weight: .bold))
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
                            .font(.system(size: 13))
                        Image(systemName: isVocabExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "F97316"))
                    .padding(.horizontal, 12)
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
                        ("pen", "钢笔"), ("pencil case", "铅笔盒"), ("ruler", "尺子"),
                        ("book", "书"), ("paper", "纸")
                    ])

                    // 教室设施
                    vocabCategoryCard(title: "教室设施", words: [
                        ("desk", "书桌"), ("chair", "椅子"), ("bookcase", "书柜"),
                        ("cupboard", "橱柜"), ("door", "门"), ("window", "窗户"),
                        ("wall", "墙"), ("board", "黑板")
                    ])

                    // 人物与场所
                    vocabCategoryCard(title: "人物与场所", words: [
                        ("teacher", "老师"), ("classroom", "教室"), ("playground", "操场")
                    ])

                    // 其他物品
                    vocabCategoryCard(title: "其他物品", words: [
                        ("bag", "书包"), ("picture", "图片"), ("television", "电视")
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
                    .foregroundStyle(Color(hex: "F97316"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                // 句型组1：Where's...? It's...（不在此教授单复数，It's不加粗）
                sentenceGroup(title: "询问物品位置") {
                    VStack(spacing: 10) {
                        // 问句
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F97316")))

                            Text("Where's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "F97316")) +
                            Text(" the pencil?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "F97316"))

                            speakerButton(text: "Where's the pencil?")

                            Spacer()

                            Text("铅笔在哪里？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        // 答句
                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "F97316"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FFF7ED")).overlay(Circle().stroke(Color(hex: "F97316"))))

                            Text("It's ")
                                .font(.system(size: 16)) +
                            Text("on")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" the desk.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's on the desk.")

                            Spacer()

                            Text("在书桌上")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        // 其他介词变体
                        VStack(alignment: .leading, spacing: 8) {
                            Text("其他位置表达：")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "9CA3AF"))

                            HStack(spacing: 4) {
                                Text("It's ")
                                    .font(.system(size: 14)) +
                                Text("in")
                                    .font(.system(size: 14, weight: .bold)) +
                                Text(" the bag.")
                                    .font(.system(size: 14))

                                speakerButton(text: "It's in the bag.", size: 14)

                                Spacer()

                                Text("在书包里")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .foregroundStyle(Color(hex: "4B5563"))

                            HStack(spacing: 4) {
                                Text("It's ")
                                    .font(.system(size: 14)) +
                                Text("under")
                                    .font(.system(size: 14, weight: .bold)) +
                                Text(" the book.")
                                    .font(.system(size: 14))

                                speakerButton(text: "It's under the book.", size: 14)

                                Spacer()

                                Text("在书下面")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .foregroundStyle(Color(hex: "4B5563"))

                            HStack(spacing: 4) {
                                Text("It's ")
                                    .font(.system(size: 14)) +
                                Text("next to")
                                    .font(.system(size: 14, weight: .bold)) +
                                Text(" the chair.")
                                    .font(.system(size: 14))

                                speakerButton(text: "It's next to the chair.", size: 14)

                                Spacer()

                                Text("在椅子旁边")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }
                            .foregroundStyle(Color(hex: "4B5563"))
                        }
                    }
                }

                // 句型组2：What's this?（不在此教授单复数，It's不加粗）
                sentenceGroup(title: "询问这是什么（单数）") {
                    HStack(spacing: 8) {
                        Text("Q")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(hex: "F97316")))

                        Text("What's this?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "F97316"))

                        speakerButton(text: "What's this?")

                        Spacer()

                        Text("这是什么？")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    HStack(spacing: 8) {
                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(hex: "FFF7ED")).overlay(Circle().stroke(Color(hex: "F97316"))))

                        Text("It's a pencil case.")
                            .font(.system(size: 16))

                        speakerButton(text: "It's a pencil case.")

                        Spacer()

                        Text("这是一个铅笔盒。")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                    .foregroundStyle(Color(hex: "1F2937"))
                }

                // 句型组3：What are these?（在此教授复数，They're要加粗）
                sentenceGroup(title: "询问这些是什么（复数）") {
                    HStack(spacing: 8) {
                        Text("Q")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(hex: "F97316")))

                        Text("What are these?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(hex: "F97316"))

                        speakerButton(text: "What are these?")

                        Spacer()

                        Text("这些是什么？")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    HStack(spacing: 8) {
                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(hex: "FFF7ED")).overlay(Circle().stroke(Color(hex: "F97316"))))

                        Text("They're ")
                            .font(.system(size: 16, weight: .bold)) +
                        Text("books.")
                            .font(.system(size: 16))

                        speakerButton(text: "They're books.")

                        Spacer()

                        Text("这些是书。")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                    .foregroundStyle(Color(hex: "1F2937"))
                }
            }
        }
    }

    // MARK: - Speaker Button
    private func speakerButton(text: String, size: CGFloat = 16) -> some View {
        Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "F97316"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "FFF7ED")))
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

    // MARK: - Bottom Button
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider().background(Color(hex: "E5E7EB"))
            Button(action: {
                viewModel.startLesson(unit1Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "FBBF24")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
