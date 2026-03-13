import Foundation

struct CheckInRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let earnedCarrots: Int
    let isBonus: Bool

    init(id: UUID = UUID(), date: Date, earnedCarrots: Int, isBonus: Bool = false) {
        self.id = id
        self.date = date
        self.earnedCarrots = earnedCarrots
        self.isBonus = isBonus
    }
}

struct CheckInStats: Codable {
    var totalCheckIns: Int
    var consecutiveDays: Int
    var lastCheckInDate: Date?
    var currentCarrots: Int
    var totalCarrots: Int
}

enum CheckInReward {
    static let daily = 5
    static let consecutive3Days = 5
    static let consecutive7Days = 10
    static let studyPerMinute = 1
}
