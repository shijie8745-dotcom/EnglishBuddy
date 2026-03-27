import Foundation

/// 对话历史记录存储服务
/// 按 unit 分别存储，每个 unit 最多保留 200 条消息
class ChatHistoryStore {
    static let shared = ChatHistoryStore()

    private let maxMessagesPerUnit = 200
    private let historyKey = "chatHistory"

    private init() {}

    // MARK: - 数据模型

    /// 可持久化的消息结构（不包含音频数据）
    struct PersistableMessage: Codable {
        let id: UUID
        let text: String
        let speaker: Speaker
        let timestamp: Date
        let isError: Bool

        init(from message: ChatMessage) {
            self.id = message.id
            self.text = message.text
            self.speaker = message.speaker
            self.timestamp = message.timestamp
            self.isError = message.isError
        }

        func toChatMessage() -> ChatMessage {
            ChatMessage(
                id: id,
                text: text,
                speaker: speaker,
                timestamp: timestamp,
                isError: isError,
                audioData: nil,
                userVoiceData: nil
            )
        }
    }

    /// 存储结构：[unitId: [messages]]
    private var history: [Int: [PersistableMessage]] = [:]

    // MARK: - Public Methods

    /// 加载指定 unit 的历史记录
    func loadHistory(for unitId: Int) -> [ChatMessage] {
        // 从 UserDefaults 加载
        loadFromDisk()

        guard let persistableMessages = history[unitId] else {
            return []
        }

        return persistableMessages.map { $0.toChatMessage() }
    }

    /// 保存指定 unit 的历史记录
    func saveHistory(for unitId: Int, messages: [ChatMessage]) {
        // 转换为可持久化格式（不保存音频数据）
        let persistableMessages = messages
            .prefix(maxMessagesPerUnit)  // 只保留最新的 200 条
            .map { PersistableMessage(from: $0) }

        history[unitId] = Array(persistableMessages)
        saveToDisk()
    }

    /// 追加消息到指定 unit 的历史记录
    func appendMessages(for unitId: Int, newMessages: [ChatMessage]) {
        loadFromDisk()

        // 获取现有历史
        var existingMessages = history[unitId] ?? []

        // 追加新消息
        let persistableNewMessages = newMessages.map { PersistableMessage(from: $0) }
        existingMessages.append(contentsOf: persistableNewMessages)

        // 只保留最新的 200 条
        if existingMessages.count > maxMessagesPerUnit {
            existingMessages = Array(existingMessages.suffix(maxMessagesPerUnit))
        }

        history[unitId] = existingMessages
        saveToDisk()
    }

    /// 清除指定 unit 的历史记录
    func clearHistory(for unitId: Int) {
        loadFromDisk()
        history.removeValue(forKey: unitId)
        saveToDisk()
    }

    /// 清除所有历史记录
    func clearAllHistory() {
        history = [:]
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    // MARK: - Private Methods

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([Int: [PersistableMessage]].self, from: data) else {
            history = [:]
            return
        }
        history = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(history) else {
            print("[ChatHistoryStore] 编码失败")
            return
        }
        UserDefaults.standard.set(data, forKey: historyKey)
        print("[ChatHistoryStore] 已保存历史记录")
    }
}