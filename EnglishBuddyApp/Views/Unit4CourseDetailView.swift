import SwiftUI

struct Unit4CourseDetailView: View {
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
            ChatView(lesson: unit4Lesson)
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

            Text("Unit 4")
                .font(.system(size: 20, weight: .bold))
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
        .frame(height: 60)
        .padding(.horizontal, 16)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(hex: "E5E7EB")).frame(height: 0.5), alignment: .bottom)
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food with friends")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            Text("与朋友分享食物")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [Color(hex: "EAB308"), Color(hex: "FDE047")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EAB308"))
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
                    .foregroundStyle(Color(hex: "EAB308"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FEF9C3")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "水果类", words: [
                        ("apple", "苹果"), ("orange", "橙子"), ("banana", "香蕉"),
                        ("pear", "梨"), ("grapes", "葡萄"), ("watermelon", "西瓜"),
                        ("pineapple", "菠萝"), ("mango", "芒果"), ("peach", "桃子"),
                        ("lemon", "柠檬")
                    ])

                    vocabCategoryCard(title: "食物类", words: [
                        ("noodles", "面条"), ("rice", "米饭"), ("cake", "蛋糕"),
                        ("bread", "面包"), ("egg", "鸡蛋"), ("pies", "馅饼"),
                        ("hamburger", "汉堡包"), ("hot dog", "热狗"), ("pizza", "披萨"),
                        ("chicken", "鸡肉"), ("fish", "鱼"), ("chocolates", "巧克力"),
                        ("sweet", "糖果"), ("jelly", "果冻")
                    ])

                    vocabCategoryCard(title: "饮料类", words: [
                        ("water", "水"), ("milk", "牛奶"), ("juice", "果汁")
                    ])

                    vocabCategoryCard(title: "餐具类", words: [
                        ("plate", "盘子"), ("bowl", "碗"), ("fork", "叉子"),
                        ("knife", "刀"), ("spoon", "勺子"), ("chopsticks", "筷子"),
                        ("cup", "杯子"), ("glass", "玻璃杯")
                    ])

                    vocabCategoryCard(title: "其他", words: [
                        ("food", "食物"), ("vegetable", "蔬菜"), ("meat", "肉"),
                        ("ice cream", "冰淇淋"), ("colour", "颜色"), ("favourite", "最喜欢的")
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
                    .foregroundStyle(isExpanded ? Color(hex: "EAB308") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "EAB308"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "FEF9C3")))
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
                    .foregroundStyle(Color(hex: "EAB308"))
                Text("核心句型")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "询问喜好") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EAB308")))

                            Text("Do you like")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308")) +
                            Text(" apples?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EAB308"))

                            speakerButton(text: "Do you like apples?")

                            Spacer()

                            Text("你喜欢苹果吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FEF9C3")).overlay(Circle().stroke(Color(hex: "EAB308"))))

                            Text("Yes, I ")
                                .font(.system(size: 16)) +
                            Text("do")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, I ")
                                .font(.system(size: 16)) +
                            Text("don't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, I do.")

                            Spacer()

                            Text("是的，我喜欢。/ 不，我不喜欢。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问喜欢什么") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EAB308")))

                            Text("What do you like?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308"))

                            speakerButton(text: "What do you like?")

                            Spacer()

                            Text("你喜欢什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FEF9C3")).overlay(Circle().stroke(Color(hex: "EAB308"))))

                            Text("I like ")
                                .font(.system(size: 16)) +
                            Text("noodles.")
                                .font(.system(size: 16, weight: .bold))

                            speakerButton(text: "I like noodles.")

                            Spacer()

                            Text("我喜欢面条。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "礼貌询问意愿") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "EAB308")))

                            Text("Would you like")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308")) +
                            Text(" an apple?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EAB308"))

                            speakerButton(text: "Would you like an apple?")

                            Spacer()

                            Text("你想要一个苹果吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FEF9C3")).overlay(Circle().stroke(Color(hex: "EAB308"))))

                            Text("Yes, please. / No, thank you.")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, please.")

                            Spacer()

                            Text("好的，谢谢。/ 不用了，谢谢。")
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
                                .background(Circle().fill(Color(hex: "EAB308")))

                            Text("Would you like")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308")) +
                            Text(" some rice?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "EAB308"))

                            speakerButton(text: "Would you like some rice?")

                            Spacer()

                            Text("你想要一些米饭吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "EAB308"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "FEF9C3")).overlay(Circle().stroke(Color(hex: "EAB308"))))

                            Text("Yes, please. / No, thank you.")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, please.")

                            Spacer()

                            Text("好的，谢谢。/ 不用了，谢谢。")
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
                .foregroundStyle(Color(hex: "EAB308"))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color(hex: "FEF9C3")))
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
                viewModel.startLesson(unit4Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: 20))
                    Text("开始对话练习").font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Color(hex: "EAB308"), Color(hex: "FDE047")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "EAB308").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
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
