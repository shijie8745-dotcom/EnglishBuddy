import SwiftUI

struct FeedPetView: View {
    let pet: Pet
    let user: User
    let viewModel: CourseViewModel
    var onClose: () -> Void = {}

    @State private var showFeedAnimation = false
    @State private var showLevelUp = false
    @State private var previousLevel = 0

    var body: some View {
        ZStack {
            // Modal content
            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    Spacer()

                    Button(action: { onClose() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }

                // Pet image
                ZStack {
                    Circle()
                        .fill(Color(hex: "FEF7ED"))
                        .frame(width: 140, height: 140)

                    rabbitImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F97316"), lineWidth: 4)
                        )

                    if showFeedAnimation {
                        Text("🥕")
                            .font(.system(size: 40))
                            .transition(.scale.combined(with: .opacity))
                            .offset(y: -60)
                    }
                }

                // Pet info
                VStack(spacing: 8) {
                    Text(pet.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    HStack(spacing: 12) {
                        LevelBadge(level: pet.level)

                        Text("喂食 \(pet.totalFed) 次")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "FED7AA"))
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * pet.progressToNextLevel, height: 16)
                        }
                    }
                    .frame(height: 16)

                    HStack {
                        Text("当前经验: \(pet.experience)/\(pet.levelUpThreshold)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))

                        Spacer()

                        Text("升级还需: \(pet.levelUpThreshold - pet.experience) 经验")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "F97316"))
                    }
                }
                .padding(.horizontal, 4)

                // Carrots count
                HStack(spacing: 8) {
                    Text("🥕")
                        .font(.system(size: 24))

                    Text("当前拥有: \(user.currentCarrots) 个胡萝卜")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FFF7ED"))
                )

                // Feed button
                Button(action: {
                    attemptFeed()
                }) {
                    HStack(spacing: 8) {
                        if showFeedAnimation {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                        } else {
                            Text("🥕")
                                .font(.system(size: 20))
                        }

                        Text(user.currentCarrots > 0 ? "喂食 (消耗1个)" : "胡萝卜不足")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: user.currentCarrots > 0
                                ? [Color(hex: "F97316"), Color(hex: "FB923C")]
                                : [Color(hex: "9CA3AF"), Color(hex: "6B7280")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(
                        color: (user.currentCarrots > 0 ? Color(hex: "F97316") : Color(hex: "9CA3AF")).opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .disabled(user.currentCarrots == 0)
                .buttonStyle(.plain)

                // Tip
                Text("每次喂食获得50经验值，满100经验升1级")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 80)

            // Level up animation
            if showLevelUp {
                levelUpOverlay
            }
        }
    }

    // MARK: - Level Up Overlay
    private var levelUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated stars
                HStack(spacing: 16) {
                    Text("✨")
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(-15))

                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 60))

                        Text("升级啦！")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text("\(pet.name) 升到了 Lv.\(pet.level)")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Text("✨")
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(15))
                }

                Button(action: {
                    withAnimation {
                        showLevelUp = false
                    }
                }) {
                    Text("太棒了！")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "F97316"))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                        )
                }
            }
            .padding(40)
        }
    }

    // MARK: - Actions
    private func attemptFeed() {
        guard user.currentCarrots > 0 else { return }

        previousLevel = pet.level

        let success = viewModel.feedPet()

        if success {
            // Feed animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showFeedAnimation = true
            }

            TTSService.shared.speak("Yum! Delicious!", speed: 1.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showFeedAnimation = false
                }
            }

            // Check for level up
            if pet.level > previousLevel {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showLevelUp = true
                    }
                    TTSService.shared.speak("Level up! I'm stronger now!", speed: 1.0)
                }
            }
        }
    }
}

// MARK: - Rabbit Image Helper
private var rabbitImage: Image {
    // Try multiple paths to find the image
    let possiblePaths = [
        "/Users/wjsun/.claude/dice-projects/learning-assistant/rabbit.png",
        Bundle.main.path(forResource: "rabbit", ofType: "png"),
        Bundle.main.bundlePath + "/Resources/rabbit.png",
        Bundle.main.bundlePath + "/rabbit.png"
    ]

    for path in possiblePaths {
        if let path = path, FileManager.default.fileExists(atPath: path),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
    }

    // Fallback to system image
    return Image(systemName: "hare.fill")
}

#Preview {
    FeedPetView(pet: Pet(), user: User(), viewModel: CourseViewModel())
}
