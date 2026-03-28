import Foundation

struct ScoreResult: Codable, Identifiable {
    let id: UUID
    let lessonId: Int
    let lessonTitle: String
    let timestamp: Date

    // 四维评分（0-100）
    let overallScore: Int
    let vocabularyScore: Int
    let grammarScore: Int
    let pronunciationScore: Int
    let fluencyScore: Int

    // AI 反馈
    let feedback: String
    let encouragement: String
    let vocabularyDetails: [VocabularyScoreDetail]
    let grammarDetails: [GrammarDetail]

    // 统计信息
    let stats: SessionStats

    // 云朵币奖励
    var earnedCoins: Int {
        if overallScore >= 95 { return 5 }
        if overallScore >= 80 { return 3 }
        return 0
    }

    // 星星等级
    var starRating: Int {
        if overallScore >= 90 { return 5 }
        if overallScore >= 75 { return 4 }
        if overallScore >= 60 { return 3 }
        if overallScore >= 40 { return 2 }
        return 1
    }
}

struct VocabularyScoreDetail: Codable {
    let word: String
    let practiced: Bool
    let correct: Bool
    let pronunciationNote: String?
    let messageIndex: Int?
    var audioData: Data?

    enum CodingKeys: String, CodingKey {
        case word, practiced, correct, pronunciationNote, messageIndex
    }
}

struct GrammarDetail: Codable {
    let original: String
    let corrected: String?
    let explanation: String?
    let messageIndex: Int?
    var audioData: Data?

    enum CodingKeys: String, CodingKey {
        case original, corrected, explanation, messageIndex
    }
}

struct SessionStats: Codable {
    let totalTurns: Int
    let sessionDuration: Int
    let vocabularyPracticed: Int
    let vocabularyTotal: Int
    let correctCount: Int
    let correctedCount: Int
}
