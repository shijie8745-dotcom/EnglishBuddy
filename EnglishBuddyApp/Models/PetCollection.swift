import Foundation
import Observation

@Observable
class PetCollection: Codable {
    var currentPetId: String          // 当前使用宠物ID
    var unlockedPets: [String: UnlockedPetInfo]  // 已解锁宠物

    init(currentPetId: String = "yinzhan", unlockedPets: [String: UnlockedPetInfo] = [:]) {
        self.currentPetId = currentPetId
        // Always ensure yinzhan is unlocked by default
        var initialPets = unlockedPets
        if initialPets["yinzhan"] == nil {
            initialPets["yinzhan"] = UnlockedPetInfo(id: "yinzhan", name: "音战", unlockDate: Date())
        }
        self.unlockedPets = initialPets
    }

    enum CodingKeys: String, CodingKey {
        case currentPetId, unlockedPets
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPetId = try container.decodeIfPresent(String.self, forKey: .currentPetId) ?? "yinzhan"
        var decodedPets = try container.decodeIfPresent([String: UnlockedPetInfo].self, forKey: .unlockedPets) ?? [:]

        // Filter out old pets that are not in the new pet list
        let validPetIds = Set(BuiltInPets.allPets.map { $0.id })
        decodedPets = decodedPets.filter { validPetIds.contains($0.key) }

        // Always ensure yinzhan is unlocked by default
        if decodedPets["yinzhan"] == nil {
            decodedPets["yinzhan"] = UnlockedPetInfo(id: "yinzhan", name: "音战", unlockDate: Date())
        }

        // Ensure currentPetId is valid
        if !validPetIds.contains(currentPetId) {
            currentPetId = "yinzhan"
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
        PetDefinition(id: "yinzhan", name: "音战", imageName: "yinzhan"),
        PetDefinition(id: "kubao", name: "酷宝", imageName: "kubao"),
        PetDefinition(id: "dianmiao", name: "电喵", imageName: "dianmiao"),
        PetDefinition(id: "saibo", name: "赛博", imageName: "saibo"),
        PetDefinition(id: "fenmiao", name: "粉喵", imageName: "fenmiao"),
        PetDefinition(id: "kushao", name: "酷少", imageName: "kushao"),
        PetDefinition(id: "yinren", name: "银刃", imageName: "yinren"),
        PetDefinition(id: "luluo", name: "绿萝", imageName: "luluo"),
        PetDefinition(id: "feihong", name: "绯红", imageName: "feihong"),
        PetDefinition(id: "jiniang", name: "机娘", imageName: "jiniang"),
    ]

    static func petById(_ id: String) -> PetDefinition? {
        allPets.first { $0.id == id }
    }

    static func petNameById(_ id: String) -> String {
        allPets.first { $0.id == id }?.name ?? "未知"
    }
}
