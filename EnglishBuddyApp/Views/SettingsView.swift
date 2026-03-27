import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Bindable var user: User
    @State private var lessons: [Lesson] = LessonResourceManager.loadLessonsFromJSON()
    @State private var selectedPracticeLessonId: Int?
    @Environment(\.dismiss) private var dismiss

    // Adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var ttsTestText: String = "Hello! I'm Emii. Let's practice English together!"
    @State private var showingEditNameSheet = false
    @State private var editNameText = ""

    var body: some View {
        ZStack {
            // Background
            Color(hex: "FEF7ED")
                .ignoresSafeArea()

            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for fixed header
                    Color.clear
                        .frame(height: headerHeight)

                    // Settings content
                    VStack(spacing: 24) {
                        // Profile section
                        profileSection

                        // Practice settings section
                        practiceSection

                        // Voice settings section
                        voiceSettingsSection

                        // AI settings section
                        aiSettingsSection

                        // Statistics section
                        statisticsSection

                        // About section
                        aboutSection
                    }
                    .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                    .padding(.top, AdaptiveLayout.Dimensions.sectionSpacing(isCompact: isCompact) * 2)
                    .padding(.bottom, 32)
                }
            }

            // Fixed header (on top of scrollable content)
            VStack(spacing: 0) {
                fixedSettingsHeader
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            loadAvatar()
            selectedPracticeLessonId = user.currentPracticeLessonId ?? lessons.first?.id
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        avatarImage = uiImage
                        DataStore.shared.saveUserAvatar(data)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditNameSheet) {
            editNameSheet
        }
    }

    // MARK: - Edit Name Sheet
    private var editNameSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title
                Text("修改名字")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // Input field
                TextField("输入新名字", text: $editNameText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "F9FAFB"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
            .frame(height: 180)
            .background(Color(hex: "FEF7ED").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingEditNameSheet = false
                    }
                    .foregroundStyle(Color(hex: "6B7280"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let trimmed = editNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            user.name = trimmed
                            DataStore.shared.saveUser(user)
                        }
                        showingEditNameSheet = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "F97316"))
                }
            }
        }
        .presentationDetents([.height(220)])
    }

    // MARK: - Settings Header
    /// Fixed header height
    private var headerHeight: CGFloat {
        let navBarHeight: CGFloat = isCompact ? 56 : 64
        return safeAreaTop + navBarHeight
    }

    /// Fixed header section (stays at top while content scrolls)
    private var fixedSettingsHeader: some View {
        let headerButtonSize = AdaptiveLayout.Dimensions.headerButtonSize(isCompact: isCompact)
        return VStack(spacing: 0) {
            // Orange gradient background
            LinearGradient(
                colors: [
                    Color(hex: "F97316"),
                    Color(hex: "FB923C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                HStack {
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: headerButtonSize, height: headerButtonSize)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.2))
                            )
                    }

                    Spacer()

                    // Title
                    Text("设置")
                        .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Spacer for alignment
                    Color.clear
                        .frame(width: headerButtonSize, height: headerButtonSize)
                }
                .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                .padding(.top, safeAreaTop + (isCompact ? 12 : 16))
                .padding(.bottom, isCompact ? 14 : 20)
            )
        }
        .frame(height: headerHeight)
    }

    // 获取顶部安全区域高度
    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        let avatarSize: CGFloat = isCompact ? 70 : 80
        let cameraButtonSize: CGFloat = isCompact ? 24 : 28
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("个人资料")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            HStack(spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
                // Avatar - entire avatar is tappable
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: avatarSize, height: avatarSize)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: "FED7AA"))
                                .frame(width: avatarSize, height: avatarSize)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) + 2))
                                        .foregroundStyle(Color(hex: "F97316"))
                                )
                        }

                        // Edit button indicator (small icon at bottom right)
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F97316"))
                                .frame(width: cameraButtonSize, height: cameraButtonSize)

                            Image(systemName: "camera.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(.white)
                        }
                        .offset(x: cameraButtonSize / 2, y: cameraButtonSize / 2)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    // Name with edit button
                    HStack(spacing: 8) {
                        Text(user.name)
                            .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                            .foregroundStyle(Color(hex: "1F2937"))

                        Button(action: {
                            editNameText = user.name
                            showingEditNameSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "F97316"))
                        }
                    }

                    Text("点击头像更换照片")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                Spacer()
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Practice Section (练一练设置)
    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("练一练设置")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            // Description text
            Text("选择你想学的课程，点击首页「练一练」可快速进入")
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.leading, 22)

            LazyVGrid(columns: AdaptiveLayout.gridColumns(count: AdaptiveLayout.Dimensions.vocabularyGridColumns(isCompact: isCompact), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact)), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact) + 4) {
                ForEach(lessons) { lesson in
                    PracticeLessonCard(
                        lesson: lesson,
                        isSelected: selectedPracticeLessonId == lesson.id,
                        isCompact: isCompact
                    )
                    .onTapGesture {
                        selectedPracticeLessonId = lesson.id
                        user.currentPracticeLessonId = lesson.id
                        DataStore.shared.saveUser(user)
                    }
                }
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Pet Section (学习宠物)
    private var petSection: some View {
        let petAvatarSize: CGFloat = isCompact ? 70 : 80
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("学习宠物")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            HStack(spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
                // Pet avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF3C7"))
                        .frame(width: petAvatarSize, height: petAvatarSize)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F59E0B"), lineWidth: 3)
                        )

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact) + 2))
                        .foregroundStyle(Color(hex: "F59E0B"))

                    // Current pet indicator
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                        .foregroundStyle(Color(hex: "10B981"))
                        .background(Circle().fill(.white))
                        .offset(x: petAvatarSize / 2 - 4, y: -petAvatarSize / 2 + 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentPetName)
                        .font(.system(size: AdaptiveLayout.Fonts.largeTitleSize(isCompact: isCompact), weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text("\(unlockedPetCount)/6 已解锁")
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                        .foregroundStyle(Color(hex: "6B7280"))

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "F59E0B"))
                            Text("\(user.cloudCoinSystem.coins)")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "10B981"))
                            Text("累计\(user.cloudCoinSystem.totalEarned)币")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                }

                Spacer()
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private var currentPetName: String {
        user.petCollection.currentPet?.name ?? "云宝"
    }

    private var unlockedPetCount: Int {
        user.petCollection.unlockedPets.count
    }

    // MARK: - Dialogue Test Section (对话测试)
    private var voiceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("对话测试")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("输入文字测试语音效果")
                    .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "9CA3AF"))

                // 输入框和试听按钮同一行
                HStack(spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
                    // 输入框
                    TextField("输入要试听的文字...", text: $ttsTestText)
                        .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                        .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "F9FAFB"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                        )

                    // 试听按钮
                    Button(action: {
                        TTSService.shared.speak(ttsTestText, speed: user.aiVoiceSpeed)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))

                            Text("试听")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                // 快捷输入提示
                HStack(spacing: 8) {
                    Text("快捷输入:")
                        .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                        .foregroundStyle(Color(hex: "9CA3AF"))

                    Button("Hello") {
                        ttsTestText = "Hello! How are you today?"
                    }
                    .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FFF7ED"))
                    )

                    Button("Good morning") {
                        ttsTestText = "Good morning! Let's learn English!"
                    }
                    .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FFF7ED"))
                    )

                    Spacer()
                }

                Divider().padding(.vertical, 8)

                // AI Test
                NavigationLink(destination: AITestView()) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 24)

                        Text("AI Test")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "1F2937"))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("进入")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                                .foregroundStyle(Color(hex: "6B7280"))

                            Image(systemName: "chevron.right")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "FFF7ED"))
                    )
                }
                .buttonStyle(.plain)

                // Chat Test
                NavigationLink(destination: ChatTestView()) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 24)

                        Text("Chat Test")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "1F2937"))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("进入")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                                .foregroundStyle(Color(hex: "6B7280"))

                            Image(systemName: "chevron.right")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "FFF7ED"))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - AI Settings Section
    private var aiSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("AI 设置")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 16) {
                // Model Info (Fixed)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI 模型")
                            .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "4B5563"))

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                                .foregroundStyle(Color(hex: "10B981"))

                            Text("qwen3.5-plus")
                                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                                .foregroundStyle(Color(hex: "1F2937"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "ECFDF5"))
                        )
                    }

                    Text("使用阿里云通义千问模型 qwen3.5-plus，支持中英文对话")
                        .font(.system(size: AdaptiveLayout.Fonts.tinySize(isCompact: isCompact)))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("学习统计")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 16) {
                StatRow(icon: "clock.fill", iconColor: Color(hex: "3B82F6"), title: "总学习时长", value: "\(user.totalStudyTime) 分钟", isCompact: isCompact)
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "book.fill", iconColor: Color(hex: "10B981"), title: "学习次数", value: "\(user.totalSessions) 次", isCompact: isCompact)
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "flame.fill", iconColor: Color(hex: "EF4444"), title: "连续学习", value: "\(user.streakDays) 天", isCompact: isCompact)
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "calendar.badge.checkmark", iconColor: Color(hex: "8B5CF6"), title: "累计签到", value: "\(user.cloudCoinSystem.checkInRecords.count) 天", isCompact: isCompact)
            }
            .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact)))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("关于")
                    .font(.system(size: AdaptiveLayout.Fonts.bodySize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 0) {
                AboutRow(title: "应用名称", value: "EnglishBuddy", isCompact: isCompact)
                Divider().padding(.leading, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                AboutRow(title: "版本", value: "1.0.0", isCompact: isCompact)
                Divider().padding(.leading, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
                AboutRow(title: "教材", value: "Power Up Level 1", isCompact: isCompact)
            }
            .background(
                RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func loadAvatar() {
        if let data = DataStore.loadUserAvatar(),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
}

// MARK: - Practice Lesson Card
struct PracticeLessonCard: View {
    let lesson: Lesson
    let isSelected: Bool
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            // Radio button style indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "F97316") : Color(hex: "E5E7EB"))
                    .frame(width: isCompact ? 20 : 22, height: isCompact ? 20 : 22)

                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
            }

            // Lesson info
            VStack(alignment: .leading, spacing: 2) {
                Text("Unit \(lesson.id) - \(lesson.title)")
                    .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Color(hex: "1F2937"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .padding(.vertical, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                .fill(isSelected ? Color(hex: "FFF7ED") : Color(hex: "F9FAFB"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact), style: .continuous)
                .stroke(isSelected ? Color(hex: "F97316") : Color(hex: "E5E7EB"), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact)) {
            Image(systemName: icon)
                .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                .foregroundStyle(iconColor)
                .frame(width: AdaptiveLayout.Dimensions.smallIconSize(isCompact: isCompact), height: AdaptiveLayout.Dimensions.smallIconSize(isCompact: isCompact))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.1))
                )

            Text(title)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(Color(hex: "4B5563"))

            Spacer()

            Text(value)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))
        }
    }
}

// MARK: - About Row
struct AboutRow: View {
    let title: String
    let value: String
    var isCompact: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
                .foregroundStyle(Color(hex: "6B7280"))

            Spacer()

            Text(value)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: .medium))
                .foregroundStyle(Color(hex: "1F2937"))
        }
        .padding(.horizontal, AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .frame(height: isCompact ? 44 : 48)
    }
}

#Preview {
    NavigationStack {
        SettingsView(user: User())
    }
}
