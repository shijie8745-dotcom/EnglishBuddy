import SwiftUI

enum AssetManager {
    static func loadAvatar() -> Image {
        if let uiImage = UIImage(named: "starman_avatar") {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "star.fill")
    }
}
