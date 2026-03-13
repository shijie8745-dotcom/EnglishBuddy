import SwiftUI

struct PetView: View {
    @State private var viewModel = CourseViewModel()
    @State private var position: CGPoint
    @GestureState private var dragOffset = CGSize.zero
    @State private var showBounce = false

    let onTapPet: () -> Void

    init(onTapPet: @escaping () -> Void = {}) {
        self.onTapPet = onTapPet
        // Load saved position
        let pet = DataStore.loadPet()
        _position = State(initialValue: CGPoint(x: pet.positionX, y: pet.positionY))
    }

    var body: some View {
        ZStack {
            // Pet avatar with info label above
            VStack(spacing: 8) {
                // Info label (above pet)
                PetInfoLabel(pet: viewModel.pet, carrots: viewModel.user.currentCarrots)
                    .offset(y: showBounce ? -5 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showBounce)

                // Pet avatar
                ZStack {
                    // Avatar
                    rabbitImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "F97316"), lineWidth: 3)
                        )
                        .shadow(color: Color(hex: "F97316").opacity(0.3), radius: 10, x: 0, y: 4)
                        .scaleEffect(showBounce ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showBounce)

                    // Carrot badge (bottom right)
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F97316"))
                            .frame(width: 32, height: 32)

                        Text("🥕")
                            .font(.system(size: 14))

                        Text("\(viewModel.user.currentCarrots)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(y: 12)
                    }
                    .offset(x: 28, y: 28)
                }
                .onTapGesture {
                    onTapPet()
                }
            }
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let newX = position.x + value.translation.width
                        let newY = position.y + value.translation.height

                        // Keep within screen bounds
                        let boundedX = max(60, min(UIScreen.main.bounds.width - 60, newX))
                        let boundedY = max(120, min(UIScreen.main.bounds.height - 100, newY))

                        position = CGPoint(x: boundedX, y: boundedY)
                        viewModel.updatePetPosition(x: boundedX, y: boundedY)
                    }
            )
        }
        .position(position)
        .onAppear {
            showBounce = true
        }
    }
}

// MARK: - Pet Info Label
struct PetInfoLabel: View {
    let pet: Pet
    let carrots: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(pet.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "1F2937"))

            Text("|")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "9CA3AF"))

            Text("Lv.\(pet.level)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "F97316"))

            Text("|")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "9CA3AF"))

            Text("🥕×\(carrots)")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "1F2937"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(Color(hex: "F97316").opacity(0.3), lineWidth: 1)
        )
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
    PetView()
}
