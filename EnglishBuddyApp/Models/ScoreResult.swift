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
    let grammarDetails: [GrammarDetail]
    let pronunciationDetails: [PronunciationDetail]

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

struct PronunciationDetail: Codable {
    let sentence: String
    let errorWords: [String]
    let issue: String
    let correction: String
    let messageIndex: Int?
    var audioData: Data?

    enum CodingKeys: String, CodingKey {
        case sentence, errorWords, issue, correction, messageIndex
    }
}

struct SessionStats: Codable {
    let totalTurns: Int
    let sessionDuration: Int
    let correctCount: Int
    let correctedCount: Int
}
