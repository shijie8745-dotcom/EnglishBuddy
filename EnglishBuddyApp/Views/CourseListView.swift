import SwiftUI

struct CourseListView: View {
    @State private var viewModel = CourseViewModel()
    @State private var showingCheckIn = false
    @State private var showingFeedPet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "FEF7ED")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Orange gradient header
                        headerSection

                        // Practice & Check-in Row
                        practiceAndCheckInSection
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
                            .padding(.bottom, 32)
                    }
                }

                // Draggable Pet overlay
                PetView(onTapPet: {
                    showingFeedPet = true
                })

                // Feed Pet Modal Overlay
                if showingFeedPet {
                    feedPetOverlay
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $showingCheckIn) {
                CheckInView(user: viewModel.user)
            }
        }
    }

    // MARK: - Feed Pet Overlay
    private var feedPetOverlay: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingFeedPet = false
                }

            // Modal content
            FeedPetView(
                pet: viewModel.pet,
                user: viewModel.user,
                viewModel: viewModel,
                onClose: {
                    showingFeedPet = false
                }
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
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
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EnglishBuddy")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)

                            Text("和 xixi 一起学英语")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        Spacer()

                        // Test Chat button
                        NavigationLink(destination: ChatTestView()) {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                )
                        }

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

    // MARK: - Practice & Check-in Section (并排布局)
    private var practiceAndCheckInSection: some View {
        HStack(spacing: 12) {
            // Practice Card (练一练) - 占据主要空间
            practiceCard

            // Check-in Button (签到) - 固定宽度
            checkInButton
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

    // MARK: - Check-in Button (签到)
    private var checkInButton: some View {
        Button(action: { showingCheckIn = true }) {
            VStack(spacing: 8) {
                // Large icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                Text("签到")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "F97316"))
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
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
