import Foundation

class ScoreHistoryStore {
    static let shared = ScoreHistoryStore()
    private let key = "scoreHistory"
    private let maxRecords = 30

    private init() {}

    func saveScore(_ score: ScoreResult) {
        var scores = loadAllScores()
        scores.insert(score, at: 0) // 最新的在前面

        // 超过上限时移除最旧的
        if scores.count > maxRecords {
            scores = Array(scores.prefix(maxRecords))
        }

        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadAllScores() -> [ScoreResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let scores = try? JSONDecoder().decode([ScoreResult].self, from: data) else {
            return []
        }
        return scores // 已按时间倒序存储
    }

    func loadScores(for lessonId: Int) -> [ScoreResult] {
        loadAllScores().filter { $0.lessonId == lessonId }
    }

    func loadLatestScore() -> ScoreResult? {
        loadAllScores().first
    }

    func deleteScore(id: UUID) {
        var scores = loadAllScores()
        scores.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
