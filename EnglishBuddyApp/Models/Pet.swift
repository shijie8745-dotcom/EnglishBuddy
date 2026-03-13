import Foundation
import Observation
import SwiftUI

@Observable
class Pet: Codable {
    var name: String
    var level: Int
    var experience: Int
    var totalFed: Int
    var positionX: CGFloat
    var positionY: CGFloat

    var levelUpThreshold: Int { level * 100 }
    var progressToNextLevel: Double { min(Double(experience) / Double(levelUpThreshold), 1.0) }

    init(name: String = "xixi", level: Int = 1, experience: Int = 0, totalFed: Int = 0, positionX: CGFloat? = nil, positionY: CGFloat? = nil) {
        self.name = name
        self.level = level
        self.experience = experience
        self.totalFed = totalFed
        // Default position: bottom right of screen with some padding
        self.positionX = positionX ?? (UIScreen.main.bounds.width - 60)
        self.positionY = positionY ?? (UIScreen.main.bounds.height - 200)
    }

    enum CodingKeys: String, CodingKey {
        case name, level, experience, totalFed, positionX, positionY
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience)
        totalFed = try container.decode(Int.self, forKey: .totalFed)
        positionX = try container.decodeIfPresent(CGFloat.self, forKey: .positionX) ?? (UIScreen.main.bounds.width - 60)
        positionY = try container.decodeIfPresent(CGFloat.self, forKey: .positionY) ?? (UIScreen.main.bounds.height - 200)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        try container.encode(totalFed, forKey: .totalFed)
        try container.encode(positionX, forKey: .positionX)
        try container.encode(positionY, forKey: .positionY)
    }

    func gainExperience(_ amount: Int) {
        experience += amount
        while experience >= levelUpThreshold {
            experience -= levelUpThreshold
            level += 1
        }
    }

    func feed() -> Bool {
        totalFed += 1
        gainExperience(50)
        return true
    }

    func updatePosition(x: CGFloat, y: CGFloat) {
        positionX = x
        positionY = y
    }
}

extension Pet {
    static let mock = Pet()
}
