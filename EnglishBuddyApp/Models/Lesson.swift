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
