import Foundation
import Observation

@Observable
class CloudCoinSystem: Codable {
    var coins: Int                    // 当前云朵币
    var totalEarned: Int              // 累计获得
    var checkInRecords: [CheckInRecord]  // 打卡记录
    var todayChatCount: Int           // 今日对话次数
    var totalChatCount: Int           // 累计对话次数（历史所有对话）
    var lastChatDate: Date?           // 最后对话日期
    var lastCheckInDate: Date?        // 最后打卡日期

    init(coins: Int = 50, totalEarned: Int = 50) {
        self.coins = coins
        self.totalEarned = totalEarned
        self.checkInRecords = []
        self.todayChatCount = 0
        self.totalChatCount = 0
        self.lastChatDate = nil
        self.lastCheckInDate = nil
    }

    enum CodingKeys: String, CodingKey {
        case coins, totalEarned, checkInRecords, todayChatCount, totalChatCount, lastChatDate, lastCheckInDate
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coins = try container.decode(Int.self, forKey: .coins)
        totalEarned = try container.decode(Int.self, forKey: .totalEarned)
        checkInRecords = try container.decode([CheckInRecord].self, forKey: .checkInRecords)
        todayChatCount = try container.decode(Int.self, forKey: .todayChatCount)
        totalChatCount = try container.decodeIfPresent(Int.self, forKey: .totalChatCount) ?? 0
        lastChatDate = try container.decodeIfPresent(Date.self, forKey: .lastChatDate)
        lastCheckInDate = try container.decodeIfPresent(Date.self, forKey: .lastCheckInDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coins, forKey: .coins)
        try container.encode(totalEarned, forKey: .totalEarned)
        try container.encode(checkInRecords, forKey: .checkInRecords)
        try container.encode(todayChatCount, forKey: .todayChatCount)
        try container.encode(totalChatCount, forKey: .totalChatCount)
        try container.encodeIfPresent(lastChatDate, forKey: .lastChatDate)
        try container.encodeIfPresent(lastCheckInDate, forKey: .lastCheckInDate)
    }

    // MARK: - Chat Count Management

    func incrementChatCount() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Reset count if it's a new day
        if let lastDate = lastChatDate,
           !calendar.isDate(lastDate, inSameDayAs: today) {
            todayChatCount = 0
        }

        todayChatCount += 1
        totalChatCount += 1  // 累计对话次数
        lastChatDate = Date()
    }

    // MARK: - Check-in Logic

    /// 检查今日是否已打卡
    var isCheckedInToday: Bool {
        guard let lastCheckIn = lastCheckInDate else { return false }
        return Calendar.current.isDateInToday(lastCheckIn)
    }

    /// 检查是否可以打卡（对话次数>=10且今日未打卡）
    var canCheckIn: Bool {
        !isCheckedInToday && todayChatCount >= 10
    }

    /// 执行打卡，返回获得的云朵币数量（0表示未满足条件）
    func performCheckIn() -> Int {
        guard canCheckIn else { return 0 }

        let consecutiveDays = calculateConsecutiveDays()
        var earnedCoins = CloudCoinReward.daily

        // 连续打卡奖励
        if consecutiveDays >= 6 { // 第7天（0-indexed第6天）
            earnedCoins += CloudCoinReward.consecutive7Days
        } else if consecutiveDays >= 2 { // 第3天（0-indexed第2天）
            earnedCoins += CloudCoinReward.consecutive3Days
        }

        // 更新数据
        coins += earnedCoins
        totalEarned += earnedCoins

        let record = CheckInRecord(date: Date(), earnedCoins: earnedCoins, isBonus: consecutiveDays >= 2)
        checkInRecords.append(record)
        lastCheckInDate = Date()

        return earnedCoins
    }

    /// 计算连续打卡天数
    private func calculateConsecutiveDays() -> Int {
        let calendar = Calendar.current
        let sortedRecords = checkInRecords.sorted { $0.date < $1.date }

        var consecutive = 0
        var checkDate = calendar.startOfDay(for: Date())

        for record in sortedRecords.reversed() {
            let recordDate = calendar.startOfDay(for: record.date)
            if calendar.isDate(recordDate, inSameDayAs: checkDate) {
                consecutive += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    checkDate = previousDay
                }
            } else if recordDate < checkDate {
                break
            }
        }

        return consecutive
    }

    // MARK: - Coin Management

    /// 赚取云朵币（学习时长：1分钟=1币）
    func earnCoinsFromStudy(minutes: Int) -> Int {
        let earned = minutes
        coins += earned
        totalEarned += earned
        return earned
    }

    /// 消费云朵币，返回是否成功
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }
}

// MARK: - Cloud Coin Rewards

enum CloudCoinReward {
    static let daily = 5           // 每日打卡
    static let consecutive3Days = 5  // 连续3天额外奖励
    static let consecutive7Days = 10 // 连续7天额外奖励
    static let studyPerMinute = 1    // 学习每分钟
    static let petPrice = 200        // 宠物价格
}

// MARK: - Updated CheckInRecord

struct CheckInRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let earnedCoins: Int
    let isBonus: Bool

    init(id: UUID = UUID(), date: Date, earnedCoins: Int, isBonus: Bool = false) {
        self.id = id
        self.date = date
        self.earnedCoins = earnedCoins
        self.isBonus = isBonus
    }
}
