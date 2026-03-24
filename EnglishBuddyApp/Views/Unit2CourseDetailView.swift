import SwiftUI

struct Unit2CourseDetailView: View {
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
            ChatView(lesson: unit2Lesson)
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

            Text("Unit 2")
                .font(.system(size: 20, weight: .bold))
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
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Banner Section
    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All about us")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("关于我们")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏带收起按钮
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EC4899"))
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
                    .foregroundStyle(Color(hex: "EC4899"))
                    .padding(.horizontal, 12)
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
                        ("mum", "妈妈"), ("dad", "爸爸"), ("sister", "姐妹"),
                        ("brother", "兄弟"), ("grandma", "奶奶/外婆"), ("grandpa", "爷爷/外公"),
                        ("friend", "朋友"), ("child", "孩子"), ("children", "孩子们")
                    ])

                    // 身体部位
                    vocabCategoryCard(title: "身体部位", words: [
                        ("head", "头"), ("eye", "眼睛"), ("ear", "耳朵"),
                        ("nose", "鼻子"), ("mouth", "嘴巴"), ("face", "脸"),
                        ("hair", "头发"), ("body", "身体"), ("arm", "手臂"),
                        ("leg", "腿"), ("foot", "脚"), ("feet", "双脚"),
                        ("hand", "手"), ("tail", "尾巴"), ("wing", "翅膀")
                    ])

                    // 外貌与颜色
                    vocabCategoryCard(title: "外貌与颜色", words: [
                        ("big", "大的"), ("small", "小的"), ("long", "长的"),
                        ("short", "短的"), ("tall", "高的"), ("fat", "胖的"),
                        ("thin", "瘦的"), ("red", "红色"), ("yellow", "黄色"),
                        ("blue", "蓝色"), ("green", "绿色"), ("white", "白色"),
                        ("black", "黑色"), ("brown", "棕色"), ("orange", "橙色")
                    ])

                    // 拓展词汇
                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("see", "看见"), ("hear", "听见"), ("touch", "触摸"), ("smell", "闻")
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
        Button(action: {
            TTSService.shared.speak(text)
        }) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size - 4))
                .foregroundStyle(Color(hex: "EC4899"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "FDF2F8")))
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
                viewModel.startLesson(unit2Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "EC4899"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "EC4899").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
