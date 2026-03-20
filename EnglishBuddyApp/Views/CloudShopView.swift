import SwiftUI

struct CloudShopView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CloudShopViewModel()
    @State private var showCheckInAnimation = false
    @State private var earnedCoins = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showPetUnlockAnimation = false
    @State private var unlockedPetName = ""

    var body: some View {
        ZStack {
            // Background
            Color(hex: "FFF7ED")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    cloudShopHeader

                    // Cloud coins section
                    cloudCoinsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Stats section
                    statsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Calendar section
                    calendarSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Check-in progress
                    checkInProgressSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Rules section
                    rulesSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Pet shop section
                    petShopSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
            }

            // Animation overlays
            if showCheckInAnimation {
                checkInAnimation
            }

            if showPetUnlockAnimation {
                petUnlockAnimation
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .alert("提示", isPresented: $showAlert) {
            Button("确定") {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            viewModel.loadData(user: user)
        }
    }

    // MARK: - Header
    private var cloudShopHeader: some View {
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
                    Text("云朵商店")
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

    // MARK: - Cloud Coins Section
    private var cloudCoinsSection: some View {
        HStack(spacing: 12) {
            // Current coins
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "F59E0B"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.cloudCoins)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text("云朵币")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )

            // Total earned
            HStack(spacing: 8) {
                Image(systemName: "dollarsign.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "10B981"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.totalEarned)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text("累计获得")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            CloudShopStatCard(
                icon: "calendar.badge.checkmark",
                iconColor: Color(hex: "8B5CF6"),
                value: "\(viewModel.totalCheckIns)",
                label: "累计打卡"
            )

            CloudShopStatCard(
                icon: "flame.fill",
                iconColor: Color(hex: "EF4444"),
                value: "\(viewModel.consecutiveDays)",
                label: "连续打卡"
            )

            CloudShopStatCard(
                icon: "bubble.left.fill",
                iconColor: Color(hex: "3B82F6"),
                value: "\(viewModel.todayChatCount)",
                label: "今日对话"
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

    // MARK: - Check-in Progress Section
    private var checkInProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "10B981"))

                Text("打卡进度")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                if viewModel.isCheckedInToday {
                    Text("今日已打卡")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                } else {
                    Text("\(viewModel.todayChatCount)/10 次对话")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6B7280"))
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FED7AA"))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(viewModel.checkInProgress) / 10.0, height: 12)
                }
            }
            .frame(height: 12)

            Text("每日对话10次即可自动打卡，获得5云朵币")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6B7280"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Rules Section
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("云朵币获取规则")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))
            }

            VStack(spacing: 12) {
                RuleRow(icon: "clock.fill", iconColor: Color(hex: "3B82F6"), text: "学习时长：每1分钟 = 1云朵币")
                RuleRow(icon: "bubble.left.fill", iconColor: Color(hex: "F59E0B"), text: "每日打卡：对话10次 = 5云朵币")
                RuleRow(icon: "flame.fill", iconColor: Color(hex: "EF4444"), text: "连续3天：额外 +5 云朵币")
                RuleRow(icon: "star.fill", iconColor: Color(hex: "FBBF24"), text: "连续7天：额外 +10 云朵币")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Pet Shop Section
    private var petShopSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("宠物商店")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                Text("200云朵币/个")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "F59E0B"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "FEF3C7"))
                    )
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(viewModel.allPets) { pet in
                    PetShopCard(
                        pet: pet,
                        isUnlocked: viewModel.isPetUnlocked(pet.id),
                        isCurrent: viewModel.currentPetId == pet.id,
                        onTap: { handlePetTap(pet: pet) }
                    )
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

    // MARK: - Check-in Animation
    private var checkInAnimation: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated coin
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF3C7"))
                        .frame(width: 120, height: 120)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(hex: "F59E0B"))
                        .scaleEffect(showCheckInAnimation ? 1.2 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCheckInAnimation)
                }

                VStack(spacing: 8) {
                    Text("打卡成功！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("获得 +\(earnedCoins) 云朵币")
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
                    showCheckInAnimation = false
                }
            }
        }
    }

    // MARK: - Pet Unlock Animation
    private var petUnlockAnimation: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated star
                ZStack {
                    Circle()
                        .fill(Color(hex: "FDF4FF"))
                        .frame(width: 120, height: 120)

                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(hex: "A855F7"))
                        .scaleEffect(showPetUnlockAnimation ? 1.2 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showPetUnlockAnimation)
                }

                VStack(spacing: 8) {
                    Text("解锁成功！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("获得新伙伴：\(unlockedPetName)")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "A855F7"), Color(hex: "C084FC")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showPetUnlockAnimation = false
                }
            }
        }
    }

    // MARK: - Actions
    private func handlePetTap(pet: PetDefinition) {
        if viewModel.isPetUnlocked(pet.id) {
            // Switch to this pet
            if viewModel.switchPet(to: pet.id, user: user) {
                // Successfully switched
            }
        } else {
            // Try to purchase
            let result = viewModel.purchasePet(petId: pet.id, user: user)
            switch result {
            case .success:
                unlockedPetName = pet.name
                withAnimation {
                    showPetUnlockAnimation = true
                }
            case .insufficientCoins:
                alertMessage = "云朵币不足，加油获取哦！"
                showAlert = true
            case .alreadyOwned:
                alertMessage = "已经有这只宠物了"
                showAlert = true
            case .failed:
                alertMessage = "购买失败，请重试"
                showAlert = true
            }
        }
    }
}

// MARK: - Cloud Shop Stat Card
struct CloudShopStatCard: View {
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

// MARK: - Pet Shop Card
struct PetShopCard: View {
    let pet: PetDefinition
    let isUnlocked: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Pet image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUnlocked ? Color(hex: "FEF3C7") : Color(hex: "F3F4F6"))
                        .frame(width: 72, height: 72)

                    if isUnlocked {
                        // Use system image for now, replace with actual pet image
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: "F59E0B"))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }

                    // Current indicator
                    if isCurrent {
                        VStack {
                            Spacer()
                            Text("使用中")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "F97316"))
                                )
                        }
                        .offset(y: 4)
                    }
                }

                Text(pet.name)
                    .font(.system(size: 13, weight: isUnlocked ? .semibold : .regular))
                    .foregroundStyle(isUnlocked ? Color(hex: "1F2937") : Color(hex: "9CA3AF"))
            }
        }
        .buttonStyle(.plain)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    CloudShopView(user: User())
}
