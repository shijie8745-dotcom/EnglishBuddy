import SwiftUI

struct Unit7CourseDetailView: View {
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
            ChatView(lesson: unit7Lesson)
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

            Text("Unit 7")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit7Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit7Lesson) == .completed {
                        viewModel.uncompleteLesson(unit7Lesson)
                    } else {
                        viewModel.completeLesson(unit7Lesson, studyTime: 5)
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
            Text("Let's play")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("让我们一起玩！")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "6EE7B7")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "10B981"))
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
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "ECFDF5")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "运动项目", words: [
                        ("football", "足球"), ("basketball", "篮球"), ("table tennis", "乒乓球"),
                        ("tennis", "网球"), ("swimming", "游泳"), ("running", "跑步"),
                        ("jumping", "跳跃"), ("skating", "滑冰"), ("riding", "骑行")
                    ])

                    vocabCategoryCard(title: "动作词汇", words: [
                        ("play", "玩/打"), ("kick", "踢"), ("throw", "扔"),
                        ("catch", "接"), ("bounce", "拍/弹"), ("hit", "打"),
                        ("pass", "传"), ("run", "跑"), ("jump", "跳"),
                        ("swim", "游泳"), ("skate", "滑冰"), ("ride", "骑")
                    ])

                    vocabCategoryCard(title: "能力与邀请", words: [
                        ("can", "能/会"), ("can't", "不能/不会"), ("well", "好地"),
                        ("try", "尝试"), ("let's", "让我们"), ("together", "一起"),
                        ("team", "队伍"), ("game", "游戏/比赛"), ("fun", "乐趣")
                    ])

                    vocabCategoryCard(title: "其他", words: [
                        ("boy", "男孩"), ("girl", "女孩"), ("children", "孩子们")
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
                    .foregroundStyle(isExpanded ? Color(hex: "10B981") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "10B981"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "ECFDF5")))
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

    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "10B981"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "询问正在做什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "10B981")))

                            Text("What are you doing?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "What are you doing?")

                            Spacer()

                            Text("你在做什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("I'm")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" playing football.")
                                .font(.system(size: 16))

                            speakerButton(text: "I'm playing football.")

                            Spacer()

                            Text("我在踢足球。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))

                        Divider().padding(.vertical, 4)

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("I'm")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" playing basketball.")
                                .font(.system(size: 16))

                            speakerButton(text: "I'm playing basketball.")

                            Spacer()

                            Text("我在打篮球。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问第三者在做什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "10B981")))

                            Text("What's he doing?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "What's he doing?")

                            Spacer()

                            Text("他在做什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("He's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" playing table tennis.")
                                .font(.system(size: 16))

                            speakerButton(text: "He's playing table tennis.")

                            Spacer()

                            Text("他在打乒乓球。")
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
                                .background(Circle().fill(Color(hex: "10B981")))

                            Text("What's she doing?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "What's she doing?")

                            Spacer()

                            Text("她在做什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("She's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" swimming.")
                                .font(.system(size: 16))

                            speakerButton(text: "She's swimming.")

                            Spacer()

                            Text("她在游泳。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问能力") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "10B981")))

                            Text("Can you")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981")) +
                            Text(" play football?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "Can you play football?")

                            Spacer()

                            Text("你会踢足球吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("Yes, I ") +
                            Text("can")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I ") +
                            Text("can't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, I can.")

                            Spacer()

                            Text("是的，我会。/ 不，我不会。")
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
                                .background(Circle().fill(Color(hex: "10B981")))

                            Text("Can you")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981")) +
                            Text(" swim well?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "Can you swim well?")

                            Spacer()

                            Text("你游泳游得好吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("Yes, I ") +
                            Text("can")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I ") +
                            Text("can't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, I can.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "提议一起运动") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Let's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981")) +
                            Text(" play table tennis!")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "10B981"))

                            speakerButton(text: "Let's play table tennis!")

                            Spacer()

                            Text("我们打乒乓球吧！")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFDF5")).overlay(Circle().stroke(Color(hex: "10B981"))))

                            Text("Good idea! / OK!")
                                .font(.system(size: 16))

                            speakerButton(text: "Good idea!")

                            Spacer()

                            Text("好主意！/ 好的！")
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
                .foregroundStyle(Color(hex: "10B981"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "ECFDF5")))
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
                viewModel.startLesson(unit7Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "10B981"), Color(hex: "6EE7B7")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
}

private let unit7Lesson = Lesson(
    id: 7,
    title: "Let's play",
    subtitle: "让我们一起玩！",
    description: "学习运动项目和动作表达",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit7CourseDetailView(viewModel: CourseViewModel())
    }
}
