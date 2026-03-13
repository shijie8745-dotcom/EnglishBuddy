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
        Lesson(id: 0, title: "Hello!", subtitle: "打招呼和自我介绍", description: "学习如何用英语打招呼和介绍自己",
               vocabulary: [VocabularyItem(word: "hello", meaning: "你好", phonetic: "/həˈləʊ/", category: "问候", image: nil)],
               sentencePatterns: [SentencePattern(pattern: "Hello!", meaning: "你好！", example: "Hello! I'm Sam.", usage: "打招呼")])
    ]
}
