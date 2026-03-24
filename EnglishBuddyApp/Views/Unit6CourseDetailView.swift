import SwiftUI

struct Unit6CourseDetailView: View {
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
            ChatView(lesson: unit6Lesson)
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

            Text("Unit 6")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit6Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit6Lesson) == .completed {
                        viewModel.uncompleteLesson(unit6Lesson)
                    } else {
                        viewModel.completeLesson(unit6Lesson, studyTime: 5)
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
            Text("A day out")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("外出一天")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "67E8F9")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "06B6D4"))
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
                    .foregroundStyle(Color(hex: "06B6D4"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "ECFEFF")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "地点类", words: [
                        ("park", "公园"), ("zoo", "动物园"), ("school", "学校"),
                        ("cinema", "电影院"), ("lake", "湖"), ("beach", "海滩"),
                        ("mountain", "山"), ("city", "城市"), ("country", "乡村")
                    ])

                    vocabCategoryCard(title:"交通工具", words: [
                        ("bus", "公共汽车"), ("car", "汽车"), ("bike", "自行车"),
                        ("train", "火车"), ("ship", "轮船"), ("plane", "飞机"),
                        ("boat", "小船"), ("taxi", "出租车"), ("metro", "地铁")
                    ])

                    vocabCategoryCard(title: "野生动物", words: [
                        ("fox", "狐狸"), ("hippo", "河马"), ("monkey", "猴子"),
                        ("tiger", "老虎"), ("lion", "狮子"), ("elephant", "大象"),
                        ("bear", "熊"), ("wolf", "狼"), ("snake", "蛇")
                    ])

                    vocabCategoryCard(title: "其他", words: [
                        ("trip", "旅行"), ("_picnic", "野餐"), ("family", "家庭"),
                        ("visit", "参观"), ("see", "看见"), ("near", "附近")
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
                    .foregroundStyle(isExpanded ? Color(hex: "06B6D4") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "06B6D4"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "ECFEFF")))
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
                    .foregroundStyle(Color(hex: "06B6D4"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "询问某地有什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "06B6D4")))

                            Text("What's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" at the zoo?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "What's at the zoo?")

                            Spacer()

                            Text("动物园里有什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFEFF")).overlay(Circle().stroke(Color(hex: "06B6D4"))))

                            Text("There are")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" many animals.")
                                .font(.system(size: 16))

                            speakerButton(text: "There are many animals.")

                            Spacer()

                            Text("有很多动物。")
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
                                .background(Circle().fill(Color(hex: "06B6D4")))

                            Text("What's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" in the park?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "What's in the park?")

                            Spacer()

                            Text("公园里有什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFEFF")).overlay(Circle().stroke(Color(hex: "06B6D4"))))

                            Text("There's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" a lake.")
                                .font(.system(size: 16))

                            speakerButton(text: "There's a lake.")

                            Spacer()

                            Text("有一个湖。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "提议一起行动") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Let's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" go to the zoo!")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "Let's go to the zoo!")

                            Spacer()

                            Text("我们去动物园吧！")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("Let's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" go by bus.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "Let's go by bus.")

                            Spacer()

                            Text("我们坐公交车去吧。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("Let's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" go by bike.")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "Let's go by bike.")

                            Spacer()

                            Text("我们骑自行车去吧。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                }

                sentenceGroup(title: "询问某地是否有某物") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "06B6D4")))

                            Text("Is there")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" a lake?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "Is there a lake?")

                            Spacer()

                            Text("有湖吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFEFF")).overlay(Circle().stroke(Color(hex: "06B6D4"))))

                            Text("Yes, ") +
                            Text("there is").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, ") +
                            Text("there isn't").font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, there is.")

                            Spacer()

                            Text("有。/ 没有。")
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
                                .background(Circle().fill(Color(hex: "06B6D4")))

                            Text("Are there")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4")) +
                            Text(" any tigers?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "06B6D4"))

                            speakerButton(text: "Are there any tigers?")

                            Spacer()

                            Text("有老虎吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "06B6D4"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "ECFEFF")).overlay(Circle().stroke(Color(hex: "06B6D4"))))

                            Text("Yes, ") +
                            Text("there are").font(.system(size: 16, weight: .bold)) +
                            Text(". / No, ") +
                            Text("there aren't").font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, there are.")

                            Spacer()

                            Text("有。/ 没有。")
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
                .foregroundStyle(Color(hex: "06B6D4"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "ECFEFF")))
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
                viewModel.startLesson(unit6Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "06B6D4"), Color(hex: "67E8F9")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "06B6D4").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
}

private let unit6Lesson = Lesson(
    id: 6,
    title: "A day out",
    subtitle: "外出一天",
    description: "学习地点、交通工具和野生动物",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit6CourseDetailView(viewModel: CourseViewModel())
    }
}
