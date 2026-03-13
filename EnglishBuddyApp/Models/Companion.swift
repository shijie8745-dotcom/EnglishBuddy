import Foundation
import Observation

enum CompanionMood: String, Codable {
    case happy, normal, tired
}

@Observable
class Companion: Codable {
    var name: String
    var level: Int
    var experience: Int
    var foodCount: Int

    @ObservationIgnored
    var mood: CompanionMood {
        if foodCount >= 5 { return .happy }
        if foodCount >= 2 { return .normal }
        return .tired
    }

    var levelUpThreshold: Int { level * 100 }
    var progressToNextLevel: Double { min(Double(experience) / Double(levelUpThreshold), 1.0) }

    init(name: String = "Sam", level: Int = 1, experience: Int = 0, foodCount: Int = 3) {
        self.name = name
        self.level = level
        self.experience = experience
        self.foodCount = foodCount
    }

    enum CodingKeys: String, CodingKey {
        case name, level, experience, foodCount
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience)
        foodCount = try container.decode(Int.self, forKey: .foodCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        try container.encode(foodCount, forKey: .foodCount)
    }

    func gainExperience(_ amount: Int) {
        experience += amount
        while experience >= levelUpThreshold {
            experience -= levelUpThreshold
            level += 1
        }
    }

    func addFood(_ amount: Int) { foodCount += amount }

    func feed() -> Bool {
        guard foodCount > 0 else { return false }
        foodCount -= 1
        gainExperience(50)
        return true
    }
}

extension Companion {
    static let mock = Companion()
}
