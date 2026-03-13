import Foundation
import Observation

@Observable
class User: Codable {
    var name: String
    var avatar: Data?
    var aiVoiceSpeed: Float
    var apiKey: String
    var selectedModel: String
    var totalStudyTime: Int
    var totalSessions: Int
    var streakDays: Int
    var lastStudyDate: Date?

    // Practice feature
    var currentPracticeLessonId: Int?

    // Carrot system (for pet feeding)
    var totalCarrots: Int
    var currentCarrots: Int

    // Check-in system
    var checkInRecords: [CheckInRecord]

    init(name: String = "小朋友", aiVoiceSpeed: Float = 1.0, apiKey: String = "", selectedModel: String = AIModel.qwen2_5_7b.rawValue, avatar: Data? = nil, totalStudyTime: Int = 0, totalSessions: Int = 0, streakDays: Int = 0, lastStudyDate: Date? = nil, currentPracticeLessonId: Int? = nil, totalCarrots: Int = 0, currentCarrots: Int = 5, checkInRecords: [CheckInRecord] = []) {
        self.name = name
        self.avatar = avatar
        self.aiVoiceSpeed = aiVoiceSpeed
        self.apiKey = apiKey
        self.selectedModel = selectedModel
        self.totalStudyTime = totalStudyTime
        self.totalSessions = totalSessions
        self.streakDays = streakDays
        self.lastStudyDate = lastStudyDate
        self.currentPracticeLessonId = currentPracticeLessonId
        self.totalCarrots = totalCarrots
        self.currentCarrots = currentCarrots
        self.checkInRecords = checkInRecords
    }

    enum CodingKeys: String, CodingKey {
        case name, avatar, aiVoiceSpeed, apiKey, selectedModel, totalStudyTime, totalSessions, streakDays, lastStudyDate
        case currentPracticeLessonId, totalCarrots, currentCarrots, checkInRecords
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decodeIfPresent(Data.self, forKey: .avatar)
        aiVoiceSpeed = try container.decode(Float.self, forKey: .aiVoiceSpeed)
        apiKey = try container.decode(String.self, forKey: .apiKey)
        selectedModel = try container.decode(String.self, forKey: .selectedModel)
        totalStudyTime = try container.decode(Int.self, forKey: .totalStudyTime)
        totalSessions = try container.decode(Int.self, forKey: .totalSessions)
        streakDays = try container.decode(Int.self, forKey: .streakDays)
        lastStudyDate = try container.decodeIfPresent(Date.self, forKey: .lastStudyDate)
        currentPracticeLessonId = try container.decodeIfPresent(Int.self, forKey: .currentPracticeLessonId)
        totalCarrots = try container.decodeIfPresent(Int.self, forKey: .totalCarrots) ?? 0
        currentCarrots = try container.decodeIfPresent(Int.self, forKey: .currentCarrots) ?? 5
        checkInRecords = try container.decodeIfPresent([CheckInRecord].self, forKey: .checkInRecords) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encode(aiVoiceSpeed, forKey: .aiVoiceSpeed)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(selectedModel, forKey: .selectedModel)
        try container.encode(totalStudyTime, forKey: .totalStudyTime)
        try container.encode(totalSessions, forKey: .totalSessions)
        try container.encode(streakDays, forKey: .streakDays)
        try container.encodeIfPresent(lastStudyDate, forKey: .lastStudyDate)
        try container.encodeIfPresent(currentPracticeLessonId, forKey: .currentPracticeLessonId)
        try container.encode(totalCarrots, forKey: .totalCarrots)
        try container.encode(currentCarrots, forKey: .currentCarrots)
        try container.encode(checkInRecords, forKey: .checkInRecords)
    }

    func recordStudySession(minutes: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastStudyDate,
           Calendar.current.startOfDay(for: lastDate) != today {
            streakDays += 1
        }
        totalStudyTime += minutes
        totalSessions += 1
        lastStudyDate = Date()
    }
}

enum AIModel: String, CaseIterable, Identifiable {
    case qwen2_5_7b = "qwen2.5-7b-instruct"
    case qwen2_5_14b = "qwen2.5-14b-instruct"
    case qwen2_5_32b = "qwen2.5-32b-instruct"
    case qwen2_5_72b = "qwen2.5-72b-instruct"
    case deepseek_v3 = "deepseek-v3"
    case deepseek_r1 = "deepseek-r1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qwen2_5_7b: return "Qwen2.5-7B (免费/快速)"
        case .qwen2_5_14b: return "Qwen2.5-14B (免费)"
        case .qwen2_5_32b: return "Qwen2.5-32B"
        case .qwen2_5_72b: return "Qwen2.5-72B"
        case .deepseek_v3: return "DeepSeek-V3"
        case .deepseek_r1: return "DeepSeek-R1"
        }
    }

    var isFree: Bool {
        switch self {
        case .qwen2_5_7b, .qwen2_5_14b: return true
        default: return false
        }
    }
}
