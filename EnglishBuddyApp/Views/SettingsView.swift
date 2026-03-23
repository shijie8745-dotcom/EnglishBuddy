import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Bindable var user: User
    @State private var lessons: [Lesson] = LessonResourceManager.loadLessonsFromJSON()
    @State private var selectedPracticeLessonId: Int?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var ttsTestText: String = "Hello! I'm Amy. Let's practice English together!"
    @State private var showingEditNameSheet = false
    @State private var editNameText = ""

    var body: some View {
        ZStack {
            // Background
            Color(hex: "FEF7ED")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    settingsHeader

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
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
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
    private var settingsHeader: some View {
        ZStack {
            // Orange gradient background
            LinearGradient(
                colors: [
                    Color(hex: "F97316"),
                    Color(hex: "FB923C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                HStack {
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.2))
                            )
                    }

                    Spacer()

                    // Title
                    Text("设置")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Spacer for alignment
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("个人资料")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            HStack(spacing: 16) {
                // Avatar - entire avatar is tappable
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: "FED7AA"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(Color(hex: "F97316"))
                                )
                        }

                        // Edit button indicator (small icon at bottom right)
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F97316"))
                                .frame(width: 28, height: 28)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 28, y: 28)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    // Name with edit button
                    HStack(spacing: 8) {
                        Text(user.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "1F2937"))

                        Button(action: {
                            editNameText = user.name
                            showingEditNameSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "F97316"))
                        }
                    }

                    Text("点击头像更换照片")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("练一练设置")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            // Description text
            Text("选择你想学的课程，点击首页「练一练」可快速进入")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .padding(.leading, 22)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(lessons) { lesson in
                    PracticeLessonCard(
                        lesson: lesson,
                        isSelected: selectedPracticeLessonId == lesson.id
                    )
                    .onTapGesture {
                        selectedPracticeLessonId = lesson.id
                        user.currentPracticeLessonId = lesson.id
                        DataStore.shared.saveUser(user)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Pet Section (学习宠物)
    private var petSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("学习宠物")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            HStack(spacing: 16) {
                // Pet avatar
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF3C7"))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F59E0B"), lineWidth: 3)
                        )

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "F59E0B"))

                    // Current pet indicator
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "10B981"))
                        .background(Circle().fill(.white))
                        .offset(x: 28, y: -28)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentPetName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text("\(unlockedPetCount)/6 已解锁")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "F59E0B"))
                            Text("\(user.cloudCoinSystem.coins)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "10B981"))
                            Text("累计\(user.cloudCoinSystem.totalEarned)币")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("对话测试")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 0) {
                // Voice test (TTS)
                VStack(alignment: .leading, spacing: 12) {
                    Text("语音测试：输入文字试听效果")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "9CA3AF"))

                // 输入框和试听按钮同一行
                HStack(spacing: 12) {
                    // 输入框
                    TextField("输入要试听的文字...", text: $ttsTestText)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
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
                                .font(.system(size: 14))

                            Text("试听")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
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
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "9CA3AF"))

                    Button("Hello") {
                        ttsTestText = "Hello! How are you today?"
                    }
                    .font(.system(size: 12))
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
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "F97316"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FFF7ED"))
                    )

                    Spacer()
                }

                // 快捷输入下方的分隔线
                Divider()
                    .padding(.top, 8)

                // AI Test
                NavigationLink(destination: AITestView()) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 24)

                        Text("AI 对话测试")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("测试")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "1F2937"))

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()

                // Chat Test
                NavigationLink(destination: ChatTestView()) {
                    HStack {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "F97316"))
                            .frame(width: 24)

                        Text("聊天界面测试")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))

                        Spacer()

                        HStack(spacing: 4) {
                            Text("测试")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "1F2937"))

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("AI 设置")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 16) {
                // Model Info (Fixed)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI 模型")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "4B5563"))

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "10B981"))

                            Text("qwen3.5-plus")
                                .font(.system(size: 14, weight: .medium))
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
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))
                Text("学习统计")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 16) {
                StatRow(icon: "clock.fill", iconColor: Color(hex: "3B82F6"), title: "总学习时长", value: "\(user.totalStudyTime) 分钟")
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "book.fill", iconColor: Color(hex: "10B981"), title: "学习次数", value: "\(user.totalSessions) 次")
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "flame.fill", iconColor: Color(hex: "EF4444"), title: "连续学习", value: "\(user.streakDays) 天")
                Divider().background(Color(hex: "E5E7EB"))
                StatRow(icon: "calendar.badge.checkmark", iconColor: Color(hex: "8B5CF6"), title: "累计签到", value: "\(user.cloudCoinSystem.checkInRecords.count) 天")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("关于")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 0) {
                AboutRow(title: "应用名称", value: "EnglishBuddy")
                Divider().padding(.leading, 16)
                AboutRow(title: "版本", value: "1.0.0")
                Divider().padding(.leading, 16)
                AboutRow(title: "教材", value: "Power Up Level 1")
                Divider().padding(.leading, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    var body: some View {
        HStack(spacing: 12) {
            // Radio button style indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "F97316") : Color(hex: "E5E7EB"))
                    .frame(width: 22, height: 22)

                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
            }

            // Lesson info
            VStack(alignment: .leading, spacing: 2) {
                Text("Unit \(lesson.id) - \(lesson.title)")
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Color(hex: "1F2937"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color(hex: "FFF7ED") : Color(hex: "F9FAFB"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.1))
                )

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "4B5563"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "1F2937"))
        }
    }
}

// MARK: - About Row
struct AboutRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6B7280"))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "1F2937"))
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
}

#Preview {
    NavigationStack {
        SettingsView(user: User())
    }
}
