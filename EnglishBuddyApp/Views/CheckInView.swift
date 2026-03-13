import SwiftUI

struct CheckInView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CheckInViewModel()
    @State private var showAnimation = false
    @State private var earnedCarrots = 0

    var body: some View {
        ZStack {
            // Background
            Color(hex: "FEF7ED")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    checkInHeader

                    // Stats section
                    statsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Calendar section
                    calendarSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Check-in button
                    checkInButton
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // Rules section
                    rulesSection
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }

            // Animation overlay
            if showAnimation {
                checkInAnimation
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            viewModel.loadCheckInData(user: user)
        }
    }

    // MARK: - Header
    private var checkInHeader: some View {
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
                    Text("每日签到")
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

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            CheckInStatCard(
                icon: "calendar.badge.checkmark",
                iconColor: Color(hex: "8B5CF6"),
                value: "\(viewModel.totalCheckIns)",
                label: "累计签到"
            )

            CheckInStatCard(
                icon: "flame.fill",
                iconColor: Color(hex: "EF4444"),
                value: "\(viewModel.consecutiveDays)",
                label: "连续天数"
            )

            CheckInStatCard(
                icon: "carrot.fill",
                iconColor: Color(hex: "F97316"),
                value: "\(user.totalCarrots)",
                label: "获得胡萝卜"
            )
        }
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(viewModel.currentYear)年\(viewModel.currentMonth)月")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                // Month navigation
                HStack(spacing: 16) {
                    Button(action: { viewModel.previousMonth() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }

                    Button(action: { viewModel.nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }
            }

            // Weekday headers
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(viewModel.calendarDays) { day in
                    CalendarDayCell(day: day, isToday: viewModel.isToday(day.date))
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

    // MARK: - Check-in Button
    private var checkInButton: some View {
        Button(action: {
            performCheckIn()
        }) {
            HStack(spacing: 8) {
                if viewModel.isCheckedInToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("今日已签到")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20))
                    Text("立即签到")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: viewModel.isCheckedInToday
                        ? [Color(hex: "9CA3AF"), Color(hex: "6B7280")]
                        : [Color(hex: "F97316"), Color(hex: "FB923C")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: (viewModel.isCheckedInToday ? Color(hex: "9CA3AF") : Color(hex: "F97316")).opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isCheckedInToday)
        .buttonStyle(.plain)
    }

    // MARK: - Rules Section
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("签到规则")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                RuleRow(icon: "carrot.fill", iconColor: Color(hex: "F97316"), text: "每日签到：+5 胡萝卜")
                RuleRow(icon: "flame.fill", iconColor: Color(hex: "EF4444"), text: "连续3天：额外 +5 胡萝卜")
                RuleRow(icon: "star.fill", iconColor: Color(hex: "FBBF24"), text: "连续7天：额外 +10 胡萝卜")
                RuleRow(icon: "clock.fill", iconColor: Color(hex: "3B82F6"), text: "每学习1分钟：+1 胡萝卜")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Check-in Animation
    private var checkInAnimation: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated carrot
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF7ED"))
                        .frame(width: 120, height: 120)

                    Text("🥕")
                        .font(.system(size: 60))
                        .scaleEffect(showAnimation ? 1.2 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showAnimation)
                }

                VStack(spacing: 8) {
                    Text("签到成功！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("获得 +\(earnedCarrots) 胡萝卜")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showAnimation = false
                }
            }
        }
    }

    // MARK: - Actions
    private func performCheckIn() {
        let earned = viewModel.checkIn(user: user)
        if earned > 0 {
            earnedCarrots = earned
            withAnimation {
                showAnimation = true
            }
        }
    }
}

// MARK: - Check-in Stat Card
struct CheckInStatCard: View {
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

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: CalendarDay
    let isToday: Bool

    var body: some View {
        ZStack {
            // Background
            if day.isCheckedIn {
                // Checked in - green gradient
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "22c55e"), Color(hex: "16a34a")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else if isToday && !day.isCheckedIn {
                // Today not checked in - orange border
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(hex: "F97316"), lineWidth: 2)
                    )
            } else {
                // Other days - gray background
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "F3F4F6"))
            }

            // Day number
            Text("\(day.day)")
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundStyle(
                    day.isCheckedIn
                        ? .white
                        : (isToday ? Color(hex: "F97316") : Color(hex: "1F2937"))
                )
        }
        .frame(height: 40)
        .opacity(day.isCurrentMonth ? 1.0 : 0.3)
    }
}

// MARK: - Rule Row
struct RuleRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.1))
                )

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "4B5563"))

            Spacer()
        }
    }
}

#Preview {
    CheckInView(user: User())
}
