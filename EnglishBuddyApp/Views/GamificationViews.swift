import SwiftUI

struct CompanionCard: View {
    let companion: Companion
    let onFeed: () -> Bool

    @State private var showFeedAnimation = false
    @State private var showNoFoodAlert = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            avatarSection

            // Info
            infoSection

            Spacer()

            // Progress
            progressSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .alert("没有食物了", isPresented: $showNoFoodAlert) {
            Button("继续学习获取") {}
        } message: {
            Text("完成更多课程来获得食物")
        }
    }

    private var avatarSection: some View {
        ZStack {
            // Avatar - Starman from file path
            starmanImage
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 8, x: 0, y: 4)

            // Mood indicator
            moodBadge
                .offset(x: 22, y: -22)

            // Feed animation
            if showFeedAnimation {
                Image(systemName: "apple.logo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "F97316"))
                    .transition(.scale.combined(with: .opacity))
                    .offset(y: -40)
            }
        }
    }

    private var moodBadge: some View {
        Circle()
            .fill(moodColor)
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: moodIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }

    private var starmanImage: Image {
        // Try multiple paths to find the image
        let possiblePaths = [
            Bundle.main.path(forResource: "starman", ofType: "png", inDirectory: "Assets"),
            Bundle.main.path(forResource: "starman", ofType: "png"),
            Bundle.main.bundlePath + "/Resources/Assets/starman.png",
            Bundle.main.bundlePath + "/Assets/starman.png"
        ]

        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path),
               let uiImage = UIImage(contentsOfFile: path) {
                return Image(uiImage: uiImage)
            }
        }

        // Fallback - try to load from main bundle resource
        if let url = Bundle.main.url(forResource: "starman", withExtension: "png", subdirectory: "Assets"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }

        // Final fallback to asset catalog
        return Image("starman")
    }

    private var moodColor: Color {
        switch companion.mood {
        case .happy: return Color(hex: "FBBF24")
        case .normal: return Color(hex: "9CA3AF")
        case .tired: return Color(hex: "60A5FA")
        }
    }

    private var moodIcon: String {
        switch companion.mood {
        case .happy: return "face.smiling.fill"
        case .normal: return "face.neutral.fill"
        case .tired: return "zzz"
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(companion.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "1F2937"))

                LevelBadge(level: companion.level)
            }

            Button {
                attemptFeed()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16))
                        .foregroundStyle(foodColor)

                    Text("×\(companion.foodCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(foodColor)

                    if companion.foodCount > 0 {
                        Text("点击喂食")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "F97316").opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: "FFF7ED"))
                )
            }
            .buttonStyle(.plain)
            .disabled(companion.foodCount == 0)
        }
    }

    private var foodColor: Color {
        companion.foodCount > 0 ? Color(hex: "F97316") : Color(hex: "D1D5DB")
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FED7AA"))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * companion.progressToNextLevel, height: 10)
                }
            }
            .frame(width: 90, height: 10)

            Text("\(companion.experience)/\(companion.levelUpThreshold)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
    }

    private func attemptFeed() {
        guard companion.foodCount > 0 else {
            showNoFoodAlert = true
            return
        }

        let success = onFeed()
        if success {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showFeedAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showFeedAnimation = false
                }
            }

            TTSService.shared.speak("Yum!", speed: 1.0)
        }
    }
}

struct LevelBadge: View {
    let level: Int

    var body: some View {
        Text("Lv\(level)")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}
