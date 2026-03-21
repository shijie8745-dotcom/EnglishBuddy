import Foundation
import Observation

@Observable
class PetCollection: Codable {
    var currentPetId: String          // 当前使用宠物ID
    var unlockedPets: [String: UnlockedPetInfo]  // 已解锁宠物

    init(currentPetId: String = "yunbao", unlockedPets: [String: UnlockedPetInfo] = [:]) {
        self.currentPetId = currentPetId
        // 默认解锁云宝
        var initialPets = unlockedPets
        if initialPets.isEmpty {
            initialPets["yunbao"] = UnlockedPetInfo(id: "yunbao", name: "云宝", unlockDate: Date())
        }
        self.unlockedPets = initialPets
    }

    enum CodingKeys: String, CodingKey {
        case currentPetId, unlockedPets
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPetId = try container.decodeIfPresent(String.self, forKey: .currentPetId) ?? "yunbao"
        var decodedPets = try container.decodeIfPresent([String: UnlockedPetInfo].self, forKey: .unlockedPets) ?? [:]
        // Ensure at least yunbao is unlocked
        if decodedPets.isEmpty {
            decodedPets["yunbao"] = UnlockedPetInfo(id: "yunbao", name: "云宝", unlockDate: Date())
        }
        unlockedPets = decodedPets
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentPetId, forKey: .currentPetId)
        try container.encode(unlockedPets, forKey: .unlockedPets)
    }

    // MARK: - Pet Management

    /// 检查宠物是否已解锁
    func isUnlocked(_ petId: String) -> Bool {
        unlockedPets[petId] != nil
    }

    /// 解锁宠物
    func unlockPet(id: String, name: String) {
        unlockedPets[id] = UnlockedPetInfo(id: id, name: name, unlockDate: Date())
    }

    /// 切换当前宠物
    func switchToPet(id: String) -> Bool {
        guard isUnlocked(id) else { return false }
        currentPetId = id
        return true
    }

    /// 获取当前宠物
    var currentPet: PetDefinition? {
        BuiltInPets.allPets.first { $0.id == currentPetId }
    }

    /// 获取已解锁宠物列表（按解锁时间排序）
    var unlockedPetsSorted: [UnlockedPetInfo] {
        unlockedPets.values.sorted { $0.unlockDate < $1.unlockDate }
    }

    /// 获取未解锁宠物列表
    var lockedPets: [PetDefinition] {
        BuiltInPets.allPets.filter { !isUnlocked($0.id) }
    }

    /// 获取所有宠物（已解锁在前，未解锁在后）
    var allPetsSorted: [PetDefinition] {
        let unlocked = BuiltInPets.allPets.filter { isUnlocked($0.id) }
        let locked = BuiltInPets.allPets.filter { !isUnlocked($0.id) }
        return unlocked + locked
    }
}

// MARK: - UnlockedPetInfo

struct UnlockedPetInfo: Codable {
    let id: String
    let name: String
    let unlockDate: Date
}

// MARK: - PetDefinition

struct PetDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let imageName: String
}

// MARK: - Built-in Pets

enum BuiltInPets {
    static let allPets: [PetDefinition] = [
        PetDefinition(id: "yunbao", name: "云宝", imageName: "yunbao"),
        PetDefinition(id: "biqi", name: "碧琪", imageName: "biqi"),
        PetDefinition(id: "pingguo", name: "苹果嘉儿", imageName: "pingguo"),
        PetDefinition(id: "rourou", name: "柔柔", imageName: "rourou"),
        PetDefinition(id: "zhengqi", name: "珍奇", imageName: "zhengqi"),
        PetDefinition(id: "ziyue", name: "紫悦", imageName: "ziyue"),
    ]

    static func petById(_ id: String) -> PetDefinition? {
        allPets.first { $0.id == id }
    }

    static func petById(_ id: String) -> String {
        allPets.first { $0.id == id }?.name ?? "未知"
    }
}
