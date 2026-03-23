import SwiftUI

struct CourseListView: View {
    @State private var viewModel = CourseViewModel()
    @State private var showingCloudShop = false

    // User avatar
    @State private var avatarImage: UIImage?

    // Floating pet state
    @State private var baseOffset: CGSize = .zero  // 保存的偏移量
    @State private var dragOffset: CGSize = .zero  // 当前拖动的偏移量
    @State private var isDragging = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let screenW = geometry.size.width
                let screenH = geometry.size.height
                let petSize: CGFloat = 250
                let padding: CGFloat = 10

                // Limit bounds (pet edges can't go beyond screen)
                let minX = petSize/2 + padding
                let maxX = screenW - petSize/2 - padding
                let minY = petSize/2 + padding
                let maxY = screenH - petSize/2 - padding

                // Default position: bottom right (at limit)
                let defaultX = maxX
                let defaultY = maxY

                // Total offset = base + current drag
                let totalOffsetX = baseOffset.width + dragOffset.width
                let totalOffsetY = baseOffset.height + dragOffset.height

                // Current position with offset
                let currentX = defaultX + totalOffsetX
                let currentY = defaultY + totalOffsetY

                let clampedX = min(max(currentX, minX), maxX)
                let clampedY = min(max(currentY, minY), maxY)

                ZStack {
                    // Background
                    Color(hex: "FEF7ED")
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 0) {
                            // Orange gradient header with pet
                            headerSection

                            // Practice & Cloud Shop Row
                            practiceAndCloudShopSection
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // Statistics section
                            statsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // Lesson list section
                            lessonListSection
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .padding(.bottom, 140)
                        }
                    }

                    // Floating draggable pet image - bottom right
                    floatingPetImage
                        .position(x: clampedX, y: clampedY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    // Clamp offset: can only move left/up from default position
                                    // defaultX = maxX, so max left offset is maxX-minX, max right is 0
                                    let maxOffsetLeft = minX - maxX  // negative value
                                    let maxOffsetUp = minY - maxY    // negative value

                                    let newBaseX = min(max(baseOffset.width + dragOffset.width, maxOffsetLeft), 0)
                                    let newBaseY = min(max(baseOffset.height + dragOffset.height, maxOffsetUp), 0)

                                    baseOffset = CGSize(width: newBaseX, height: newBaseY)
                                    dragOffset = .zero
                                }
                        )
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $showingCloudShop) {
                CloudShopView(user: viewModel.user)
            }
            .onAppear {
                loadAvatar()
            }
        }
    }

    private func loadAvatar() {
        if let data = DataStore.loadUserAvatar(),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
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
                    // Navigation bar area
                    HStack {
                        // Title and user avatar
                        HStack(spacing: 12) {
                            // User avatar (replaces pet avatar)
                            userAvatar

                            VStack(alignment: .leading, spacing: 4) {
                                Text("EnglishBuddy")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)

                                Text("和 Amy 一起学英语")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }

                        Spacer()

                        // Settings button
                        NavigationLink(destination: SettingsView(user: viewModel.user)) {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "gear")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - User Avatar (replaces pet avatar in header)
    private var userAvatar: some View {
        Group {
            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Floating Pet Image
    private var floatingPetImage: some View {
        petImageFromFile(named: viewModel.currentPetImageName)
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 250)
            .shadow(color: .gray.opacity(0.3), radius: 20, x: 0, y: 0)
            .shadow(color: .gray.opacity(0.2), radius: 40, x: 0, y: 0)
            .shadow(color: .gray.opacity(0.1), radius: 60, x: 0, y: 0)
    }

    private func petImageFromFile(named: String) -> Image {
        let possiblePaths = [
            "/Users/wjsun/.claude/dice-projects/learning-assistant/EnglishBuddyApp/EnglishBuddyApp/picture/pets/\(named).png",
            Bundle.main.path(forResource: named, ofType: "png", inDirectory: "pets"),
            Bundle.main.bundlePath + "/picture/pets/\(named).png"
        ]

        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path),
               let uiImage = UIImage(contentsOfFile: path) {
                return Image(uiImage: uiImage)
            }
        }

        return Image(systemName: "pawprint.fill")
    }

    // MARK: - Practice & Cloud Shop Section
    private var practiceAndCloudShopSection: some View {
        HStack(spacing: 12) {
            // Practice Card (练一练) - 占据主要空间
            practiceCard

            // Cloud Shop Button - 固定宽度
            cloudShopButton
        }
    }

    // MARK: - Practice Card (练一练)
    private var practiceCard: some View {
        let lesson = viewModel.practiceLesson
        let displayText = lesson.map { "\($0.unitTitle) - \($0.title)" } ?? "未选择课程"

        return NavigationLink(destination: {
            if let lesson = lesson {
                ChatView(lesson: lesson, isFromPractice: true)
            }
        }) {
            HStack(spacing: 12) {
                // Left side - text
                VStack(alignment: .leading, spacing: 4) {
                    Text("练一练")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Text("正在学：")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.9))

                        Text(displayText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Right side - play button
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(hex: "0d9488"))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "0d9488"),
                        Color(hex: "2dd4bf")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: "0d9488").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(lesson == nil)
        .opacity(lesson == nil ? 0.6 : 1.0)
    }

    // MARK: - Cloud Shop Button
    private var cloudShopButton: some View {
        Button(action: { showingCloudShop = true }) {
            ZStack {
                // Coin image
                coinImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var coinImage: Image {
        Image("coin")
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "book.fill",
                iconColor: Color(hex: "F97316"),
                value: "\(viewModel.completedLessonsCount)",
                label: "已完成课程"
            )

            StatCard(
                icon: "clock.fill",
                iconColor: Color(hex: "3B82F6"),
                value: "\(viewModel.totalStudyTime)",
                label: "学习分钟"
            )

            StatCard(
                icon: "flame.fill",
                iconColor: Color(hex: "EF4444"),
                value: "\(viewModel.totalSessions)",
                label: "学习次数"
            )
        }
    }

    // MARK: - Lesson List Section
    private var lessonListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("课程列表")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                Text("共\(viewModel.lessons.count)课")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            LazyVStack(spacing: 12) {
                ForEach(viewModel.lessons) { lesson in
                    NavigationLink(destination: CourseDetailView(lesson: lesson, viewModel: viewModel)) {
                        LessonRow(
                            lesson: lesson,
                            status: viewModel.status(for: lesson)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Lesson Row
struct LessonRow: View {
    let lesson: Lesson
    let status: LessonStatus

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusBackgroundColor)
                    .frame(width: 48, height: 48)

                Image(systemName: statusIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(statusForegroundColor)
            }

            // Lesson info
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.displayTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(status == .locked ? Color(hex: "9CA3AF") : Color(hex: "1F2937"))

                Text(lesson.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineLimit(1)
            }

            Spacer()

            // Lock icon if locked
            if status == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .opacity(status == .locked ? 0.7 : 1.0)
    }

    private var statusIcon: String {
        switch status {
        case .completed:
            return "checkmark.circle.fill"
        case .inProgress:
            return "play.circle.fill"
        case .locked:
            return "lock.circle.fill"
        }
    }

    private var statusBackgroundColor: Color {
        switch status {
        case .completed:
            return Color(hex: "10B981").opacity(0.1)
        case .inProgress:
            return Color(hex: "F97316").opacity(0.1)
        case .locked:
            return Color(hex: "E5E7EB")
        }
    }

    private var statusForegroundColor: Color {
        switch status {
        case .completed:
            return Color(hex: "10B981")
        case .inProgress:
            return Color(hex: "F97316")
        case .locked:
            return Color(hex: "9CA3AF")
        }
    }
}

#Preview {
    CourseListView()
}
