import SwiftUI

// MARK: - Press Button Modifier
struct PressButtonModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
    }
}

extension View {
    func pressEvents(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> some View {
        modifier(PressButtonModifier(onPress: onPress, onRelease: onRelease))
    }
}
