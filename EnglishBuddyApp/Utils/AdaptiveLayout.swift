import SwiftUI

/// 响应式布局工具类，用于 iPhone/iPad 设备适配
enum AdaptiveLayout {

    // MARK: - Adaptive Dimensions

    enum Dimensions {

        // MARK: - Pet Sizes

        /// 悬浮宠物尺寸 (iPhone 140pt / iPad 250pt)
        static func floatingPetSize(isCompact: Bool) -> CGFloat {
            isCompact ? 140 : 250
        }

        /// 宠物预览图尺寸 (iPhone 180pt / iPad 280pt)
        static func petPreviewSize(isCompact: Bool) -> CGFloat {
            isCompact ? 180 : 280
        }

        // MARK: - Avatar & Icon Sizes

        /// 头像尺寸 (iPhone 44pt / iPad 52pt)
        static func avatarSize(isCompact: Bool) -> CGFloat {
            isCompact ? 44 : 52
        }

        /// 统计图标尺寸 (iPhone 40pt / iPad 48pt)
        static func statIconSize(isCompact: Bool) -> CGFloat {
            isCompact ? 40 : 48
        }

        /// 小图标尺寸 (iPhone 36pt / iPad 44pt)
        static func smallIconSize(isCompact: Bool) -> CGFloat {
            isCompact ? 36 : 44
        }

        /// 聊天头像尺寸 (iPhone 32pt / iPad 36pt)
        static func chatAvatarSize(isCompact: Bool) -> CGFloat {
            isCompact ? 32 : 36
        }

        // MARK: - Padding

        /// 水平内边距 (iPhone 16pt / iPad 20pt)
        static func horizontalPadding(isCompact: Bool) -> CGFloat {
            isCompact ? 16 : 20
        }

        /// 卡片内边距 (iPhone 12pt / iPad 16pt)
        static func cardPadding(isCompact: Bool) -> CGFloat {
            isCompact ? 12 : 16
        }

        /// Section 间距 (iPhone 12pt / iPad 16pt)
        static func sectionSpacing(isCompact: Bool) -> CGFloat {
            isCompact ? 12 : 16
        }

        // MARK: - Grid Columns

        /// 词汇网格列数 (iPhone 2列 / iPad 3列)
        static func vocabularyGridColumns(isCompact: Bool) -> Int {
            isCompact ? 2 : 3
        }

        /// 宠物商店列数 (iPhone 3列 / iPad 4列)
        static func petShopColumns(isCompact: Bool) -> Int {
            isCompact ? 3 : 4
        }

        /// 网格间距 (iPhone 8pt / iPad 10pt)
        static func gridSpacing(isCompact: Bool) -> CGFloat {
            isCompact ? 8 : 10
        }

        // MARK: - Chat

        /// 聊天气泡最大宽度 (iPhone 85% / iPad 75%)
        static func chatBubbleMaxWidth(screenWidth: CGFloat, isCompact: Bool) -> CGFloat {
            screenWidth * (isCompact ? 0.85 : 0.75)
        }

        // MARK: - Fixed Dimensions (works for both devices)

        /// 头部高度 (60pt - 通用)
        static let headerHeight: CGFloat = 60

        /// 底部按钮高度 (56pt - 通用)
        static let bottomButtonHeight: CGFloat = 56

        /// 语音输入区域高度 (88pt - 通用)
        static let voiceInputHeight: CGFloat = 88
    }

    // MARK: - Adaptive Font Sizes

    enum Fonts {

        /// 标题字体 (iPhone 24pt / iPad 28pt)
        static func titleSize(isCompact: Bool) -> CGFloat {
            isCompact ? 24 : 28
        }

        /// 大标题 (iPhone 20pt / iPad 22pt)
        static func largeTitleSize(isCompact: Bool) -> CGFloat {
            isCompact ? 20 : 22
        }

        /// 标题字体 (iPhone 18pt / iPad 20pt)
        static func headingSize(isCompact: Bool) -> CGFloat {
            isCompact ? 18 : 20
        }

        /// 正文字体 (iPhone 14pt / iPad 16pt)
        static func bodySize(isCompact: Bool) -> CGFloat {
            isCompact ? 14 : 16
        }

        /// 小字体 (iPhone 12pt / iPad 14pt)
        static func captionSize(isCompact: Bool) -> CGFloat {
            isCompact ? 12 : 14
        }

        /// 极小字体 (iPhone 10pt / iPad 12pt)
        static func tinySize(isCompact: Bool) -> CGFloat {
            isCompact ? 10 : 12
        }
    }

    // MARK: - Helper Methods

    /// 创建自适应网格列
    static func gridColumns(count: Int, spacing: CGFloat = 10) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

// MARK: - View Extension for Adaptive Modifiers

extension View {

    /// 应用自适应水平内边距
    func adaptiveHorizontalPadding(isCompact: Bool) -> some View {
        self.padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
    }

    /// 应用自适应卡片内边距
    func adaptiveCardPadding(isCompact: Bool) -> some View {
        self.padding(AdaptiveLayout.Dimensions.cardPadding(isCompact: isCompact))
    }
}