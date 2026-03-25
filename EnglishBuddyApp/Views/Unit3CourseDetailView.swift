import SwiftUI

struct Unit3CourseDetailView: View {
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
            ChatView(lesson: unit3Lesson)
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

            Text("Unit 3")
                .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Spacer()

            CompleteButton(
                isCompleted: viewModel.status(for: unit3Lesson) == .completed,
                onToggle: {
                    if viewModel.status(for: unit3Lesson) == .completed {
                        viewModel.uncompleteLesson(unit3Lesson)
                    } else {
                        viewModel.completeLesson(unit3Lesson, studyTime: 5)
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
            Text("Fun on the farm")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(.white.opacity(0.9))
            Text("农场乐趣")
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact) + 4)
        .background(LinearGradient(colors: [Color(hex: "84CC16"), Color(hex: "A3E635")], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
    }

    // MARK: - Vocabulary Section
    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "84CC16"))
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
                    .foregroundStyle(Color(hex: "84CC16"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "F0FDF4")))
                }
                .buttonStyle(.plain)
            }

            if isVocabExpanded {
                VStack(spacing: 12) {
                    vocabCategoryCard(title: "农场动物", words: [
                        ("horse", "马"), ("cow", "牛"), ("pig", "猪"),
                        ("chicken", "鸡"), ("hen", "母鸡"), ("ducks", "鸭子（复数）"),
                        ("gander", "公鹅"), ("goose", "鹅"), ("sheep", "绵羊"),
                        ("lamb", "小羊"), ("goat", "山羊"), ("donkey", "驴")
                    ])

                    vocabCategoryCard(title: "动物形容词", words: [
                        ("big", "大的"), ("small", "小的"), ("long", "长的"),
                        ("short", "短的"), ("fat", "胖的"), ("thin", "瘦的"),
                        ("tall", "高的"), ("cute", "可爱的"), ("strong", "强壮的"),
                        ("lovely", "可爱的"), ("naughty", "淘气的")
                    ])

                    vocabCategoryCard(title: "其他名词", words: [
                        ("farm", "农场"), ("farmer", "农民"), ("zoo", "动物园"),
                        ("tree", "树"), ("grass", "草"), ("body", "身体"),
                        ("leg", "腿"), ("head", "头"), ("tail", "尾巴"),
                        ("ear", "耳朵"), ("eye", "眼睛"), ("mouth", "嘴巴")
                    ])

                    vocabCategoryCard(title: "拓展词汇", words: [
                        ("合体展示", "合体展示"), ("again please", "请再来一次"), ("quack quack", "嘎嘎"), ("oink oink", "哼哼"),
                        ("moo moo", "哞哞"), ("baa baa", "咩咩"), ("neigh", "嘶叫"), ("bee", "蜜蜂")
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
                    .foregroundStyle(isExpanded ? Color(hex: "84CC16") : Color(hex: "4B5563"))
                if isExpanded {
                    Text("拓展")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact) - 2))
                        .foregroundStyle(Color(hex: "84CC16"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "F0FDF4")))
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

    // MARK: - Sentences Section
    private var sentencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "84CC16"))
                Text("核心句型")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                sentenceGroup(title: "描述动物特征") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("What's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" this?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "What's this?")

                            Spacer()

                            Text("这是什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" a ") +
                            Text("big")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" horse.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's a big horse.")

                            Spacer()

                            Text("它是一匹大马。")
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
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("What's")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" this?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "What's this?")

                            Spacer()

                            Text("这是什么？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("It's")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" a ") +
                            Text("small")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" pig.")
                                .font(.system(size: 16))

                            speakerButton(text: "It's a small pig.")

                            Spacer()

                            Text("它是一头小猪。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "确认动物特征") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("Is it")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" big?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "Is it big?")

                            Spacer()

                            Text("它大吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("Yes, it ") +
                            Text("is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ") +
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
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("Is it")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" fat?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "Is it fat?")

                            Spacer()

                            Text("它胖吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("Yes, it ") +
                            Text("is")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ") +
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

                sentenceGroup(title: "询问是否有某种特征") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("Has it got")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" a long tail?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "Has it got a long tail?")

                            Spacer()

                            Text("它有长尾巴吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("Yes, it ") +
                            Text("has")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ") +
                            Text("hasn't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, it has.")

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
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("Has it got")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16")) +
                            Text(" two legs?")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "Has it got two legs?")

                            Spacer()

                            Text("它有两条腿吗？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("Yes, it ") +
                            Text("has")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(". / No, it ") +
                            Text("hasn't")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(".")
                                .font(.system(size: 16))

                            speakerButton(text: "Yes, it has.")

                            Spacer()

                            Text("是的。/ 不是。")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .foregroundStyle(Color(hex: "1F2937"))
                    }
                }

                sentenceGroup(title: "询问动物有什么特征") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Q")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "84CC16")))

                            Text("What has it got?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))

                            speakerButton(text: "What has it got?")

                            Spacer()

                            Text("它有什么特征？")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        HStack(spacing: 8) {
                            Text("A")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "84CC16"))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color(hex: "F0FDF4")).overlay(Circle().stroke(Color(hex: "84CC16"))))

                            Text("It has got")
                                .font(.system(size: 16, weight: .bold)) +
                            Text(" four legs and a short tail.")
                                .font(.system(size: 16))

                            speakerButton(text: "It has got four legs and a short tail.")

                            Spacer()

                            Text("它有四条腿和一条短尾巴。")
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
                .foregroundStyle(Color(hex: "84CC16"))
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .background(Circle().fill(Color(hex: "F0FDF4")))
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
                viewModel.startLesson(unit3Lesson)
                showingChat = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    Text("开始对话练习").font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) - 2, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveLayout.Dimensions.bottomButtonHeight(isCompact: isCompact))
                .background(LinearGradient(colors: [Color(hex: "84CC16"), Color(hex: "A3E635")], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous))
                .shadow(color: Color(hex: "84CC16").opacity(0.3), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
            .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(Color.white)
        }
    }
}

private let unit3Lesson = Lesson(
    id: 3,
    title: "Fun on the farm",
    subtitle: "农场乐趣",
    description: "学习农场动物和描述性形容词",
    vocabulary: [],
    sentencePatterns: []
)

#Preview {
    NavigationStack {
        Unit3CourseDetailView(viewModel: CourseViewModel())
    }
}
