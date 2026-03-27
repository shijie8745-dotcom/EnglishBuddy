import Foundation

struct Lesson: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let vocabulary: [VocabularyItem]
    let sentencePatterns: [SentencePattern]
    var displayTitle: String { "Unit \(id): \(title)" }
    var unitTitle: String { "Unit \(id)" }

    /// Topic icon matching the course content
    var topicIcon: String {
        switch id {
        case 1: return "book.fill"           // Our New School - 学校用品
        case 2: return "person.fill"         // All About Us - 身体部位
        case 3: return "leaf.fill"           // Fun on the Farm - 农场动物
        case 4: return "fork.knife"          // Food With Friends - 食物
        case 5: return "gift.fill"           // Happy Birthday! - 生日派对
        case 6: return "car.fill"            // A Day Out - 交通工具
        case 7: return "gamecontroller.fill" // Let's Play! - 运动、游戏
        case 8: return "house.fill"          // At Home - 家居用品
        case 9: return "star.fill"           // Happy Holidays! - 节日
        default: return "book.fill"
        }
    }

    /// Topic icon background color
    var topicIconColor: String {
        switch id {
        case 1: return "3B82F6"  // Blue - School
        case 2: return "EC4899"  // Pink - Body
        case 3: return "22C55E"  // Green - Farm
        case 4: return "F97316"  // Orange - Food
        case 5: return "A855F7"  // Purple - Birthday
        case 6: return "06B6D4"  // Cyan - Travel
        case 7: return "EF4444"  // Red - Play
        case 8: return "6366F1"  // Indigo - Home
        case 9: return "FBBF24"  // Yellow - Holidays
        default: return "6B7280"
        }
    }
}

struct VocabularyItem: Codable, Hashable {
    let word: String
    let meaning: String
    let phonetic: String?
    let category: String?
    let image: String?
}

struct SentencePattern: Codable, Hashable {
    let pattern: String
    let meaning: String
    let example: String
    let usage: String?
}

struct LessonProgress: Codable, Identifiable {
    let id: Int
    var isCompleted: Bool = false
    var completedDate: Date?
    var studyCount: Int = 0
    var totalStudyTime: Int = 0
    init(id: Int) { self.id = id }
    mutating func markAsCompleted() { isCompleted = true; completedDate = Date() }
    mutating func addStudyTime(_ minutes: Int) { totalStudyTime += minutes }
}

enum LessonStatus { case locked, inProgress, completed }

extension Lesson {
    static let mockLessons: [Lesson] = [
        Lesson(id: 1, title: "Our New School", subtitle: "我们的新学校", description: "学习学校用品、教室物品和方位表达",
               vocabulary: [VocabularyItem(word: "pencil", meaning: "铅笔", phonetic: "/ˈpensl/", category: "学习用品", image: nil)],
               sentencePatterns: [SentencePattern(pattern: "What's this?", meaning: "这是什么？", example: "What's this? It's a book.", usage: "询问物品")])
    ]
}
