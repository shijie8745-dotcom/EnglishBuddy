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
    @State private var selectedPetForPreview: PetDefinition? = nil

    // Adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "FFF7ED")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with coin balance
                    cloudShopHeader

                    // Pet Shop Section (now called 云朵商店)
                    petShopSection
                        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                        .padding(.top, 16)

                    // Stats section
                    statsSection
                        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                        .padding(.top, 20)

                    // Check-in progress (above calendar)
                    checkInProgressSection
                        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                        .padding(.top, 20)

                    // Calendar section
                    calendarSection
                        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
                        .padding(.top, 20)

                    // Rules section
                    rulesSection
                        .padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
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

            // Pet Preview Modal
            if let pet = selectedPetForPreview {
                petPreviewOverlay(pet: pet)
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

                    // Empty spacer for balance
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            // 为状态栏预留空间
            .padding(.top, safeAreaTop)
        }
    }

    // 获取顶部安全区域高度
    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // MARK: - Pet Shop Section (云朵商店)
    private var petShopSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "F97316"))

                Text("云朵商店")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                Spacer()

                // Cloud coin balance
                HStack(spacing: 4) {
                    coinIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("\(viewModel.cloudCoins)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "F59E0B"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: "FEF3C7"))
                )
            }

            // Pet grid - adaptive columns for 10 pets (3 rows: 4+4+2 on iPad, 3+3+3+1 on iPhone)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: AdaptiveLayout.Dimensions.petShopColumns(isCompact: isCompact)), spacing: AdaptiveLayout.Dimensions.gridSpacing(isCompact: isCompact)) {
                ForEach(viewModel.allPets) { pet in
                    PetShopCard(
                        pet: pet,
                        isUnlocked: viewModel.isPetUnlocked(pet.id),
                        isCurrent: viewModel.currentPetId == pet.id,
                        onTap: { selectedPetForPreview = pet }
                    )
                }
            }
        }
        .padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Pet Preview Overlay
    private func petPreviewOverlay(pet: PetDefinition) -> some View {
        let previewSize = AdaptiveLayout.Dimensions.petPreviewSize(isCompact: isCompact)
        return ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedPetForPreview = nil
                }

            VStack(spacing: 24) {
                // Pet image (larger)
                petImage(named: pet.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: previewSize, height: previewSize)

                // Pet name
                Text(pet.name)
                    .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                // Status
                if viewModel.isPetUnlocked(pet.id) {
                    if viewModel.currentPetId == pet.id {
                        Text("正在使用")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "10B981"))
                    } else {
                        Button(action: {
                            if viewModel.switchPet(to: pet.id, user: user) {
                                selectedPetForPreview = nil
                            }
                        }) {
                            Text("切换")
                                .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: isCompact ? 100 : 140)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                } else {
                    // Purchase button
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            coinIcon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text("200")
                                .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }

                        Button(action: {
                            handlePetPurchase(pet: pet)
                        }) {
                            Text("购买")
                                .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact), weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: isCompact ? 100 : 140)
                                .padding(.vertical, 14)
                                .background(
                                    viewModel.cloudCoins >= 200
                                        ? LinearGradient(
                                            colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            colors: [Color(hex: "9CA3AF"), Color(hex: "6B7280")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(viewModel.cloudCoins < 200)
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
            )
            .padding(.horizontal, 32)
        }
    }

    private func handlePetPurchase(pet: PetDefinition) {
        let result = viewModel.purchasePet(petId: pet.id, user: user)
        switch result {
        case .success:
            unlockedPetName = pet.name
            selectedPetForPreview = nil
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

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Year without comma
                Text(yearText)
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

            // Weekday headers - Sunday on the right (Western calendar style)
            HStack {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
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

    private var yearText: String {
        // Format year without comma
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.groupingSeparator = ""
        let yearString = String(viewModel.currentYear)
        return "\(yearString)年\(viewModel.currentMonth)月"
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

                    coinIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
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

    // MARK: - Image Helpers
    private var coinIcon: Image {
        Image("coin")
    }

    private func petImage(named: String) -> Image {
        // 从 Assets.xcassets 加载宠物图片
        Image(named)
    }
}

// MARK: - Cloud Shop Stat Card
struct CloudShopStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        let iconSize = AdaptiveLayout.Dimensions.statIconSize(isCompact: isCompact)
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: icon)
                    .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.system(size: AdaptiveLayout.Fonts.titleSize(isCompact: isCompact), weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Text(label)
                .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact)))
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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        let cardHeight: CGFloat = isCompact ? 70 : 85
        let petImageSize: CGFloat = isCompact ? 56 : 72
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Pet image
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isUnlocked ? Color(hex: "FEF3C7") : Color(hex: "F3F4F6"))
                        .frame(height: cardHeight)

                    petImage(named: pet.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: petImageSize, height: petImageSize)
                        .opacity(isUnlocked ? 1.0 : 0.5)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }

                    // Current indicator
                    if isCurrent {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: AdaptiveLayout.Fonts.headingSize(isCompact: isCompact)))
                                    .foregroundStyle(Color(hex: "10B981"))
                                    .background(Circle().fill(.white))
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                }

                Text(pet.name)
                    .font(.system(size: AdaptiveLayout.Fonts.captionSize(isCompact: isCompact), weight: isUnlocked ? .semibold : .regular))
                    .foregroundStyle(isUnlocked ? Color(hex: "1F2937") : Color(hex: "9CA3AF"))
            }
        }
        .buttonStyle(.plain)
    }

    private func petImage(named: String) -> Image {
        // 从 Assets.xcassets 加载宠物图片
        Image(named)
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

#Preview {
    CloudShopView(user: User())
}
