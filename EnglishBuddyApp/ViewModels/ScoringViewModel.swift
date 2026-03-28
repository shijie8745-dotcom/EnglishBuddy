import Foundation
import Observation

@Observable
class ScoringViewModel {
    var isScoring = false
    var scoreResult: ScoreResult?
    var showScoreResult = false
    var scoringError: String?

    // 评分范围追踪
    private var lastScoredMessageId: UUID?

    // MARK: - Scoring Range

    /// 获取待评分的消息范围
    func getScorableMessages(allMessages: [ChatMessage], sessionStartTime: Date?) -> [ChatMessage] {
        // 1. 筛选当前会话的消息
        var sessionMessages = allMessages
        if let startTime = sessionStartTime {
            sessionMessages = allMessages.filter { $0.timestamp >= startTime }
        }

        // 2. 如果有上次评分截止点，从该消息之后开始
        if let lastId = lastScoredMessageId,
           let lastIndex = sessionMessages.firstIndex(where: { $0.id == lastId }) {
            let startIndex = sessionMessages.index(after: lastIndex)
            if startIndex < sessionMessages.endIndex {
                return Array(sessionMessages[startIndex...])
            } else {
                return [] // 没有新消息
            }
        }

        return sessionMessages
    }

    /// 检查是否满足评分条件
    func canScore(allMessages: [ChatMessage], sessionStartTime: Date?) -> (Bool, String?) {
        let scorable = getScorableMessages(allMessages: allMessages, sessionStartTime: sessionStartTime)

        if scorable.isEmpty {
            return (false, "没有新的对话内容可以评分")
        }

        let userMessages = scorable.filter { $0.speaker == .user }
        if userMessages.count < 3 {
            return (false, "再多说几句再评分哦~")
        }

        return (true, nil)
    }

    // MARK: - Start Scoring

    func startScoring(
        messages: [ChatMessage],
        sessionStartTime: Date?,
        lessonId: Int,
        lessonTitle: String
    ) async {
        let scorableMessages = getScorableMessages(allMessages: messages, sessionStartTime: sessionStartTime)

        guard !scorableMessages.isEmpty else {
            await MainActor.run {
                scoringError = "没有新的对话内容可以评分"
            }
            return
        }

        await MainActor.run {
            isScoring = true
            scoringError = nil
        }

        do {
            let result = try await ScoringService.shared.scoreConversation(
                messages: scorableMessages,
                lessonId: lessonId,
                lessonTitle: lessonTitle,
                sessionStartTime: sessionStartTime
            )

            // 保存评分结果
            ScoreHistoryStore.shared.saveScore(result)

            // 奖励云朵币
            let coins = result.earnedCoins
            if coins > 0 {
                let user = DataStore.loadUser()
                user.cloudCoinSystem.coins += coins
                user.cloudCoinSystem.totalEarned += coins
                DataStore.shared.saveUser(user)
                print("[ScoringViewModel] 评分奖励 \(coins) 云朵币")
            }

            await MainActor.run {
                // 更新评分范围截止点
                lastScoredMessageId = scorableMessages.last?.id
                scoreResult = result
                isScoring = false
                showScoreResult = true
            }

            print("[ScoringViewModel] 评分完成: \(result.overallScore)分")
        } catch {
            print("[ScoringViewModel] 评分失败: \(error.localizedDescription)")
            await MainActor.run {
                isScoring = false
                scoringError = error.localizedDescription
            }
        }
    }

    // MARK: - Reset

    func resetError() {
        scoringError = nil
    }

    func dismissResult() {
        showScoreResult = false
    }
}
