import Foundation

@Observable
class ChatMessage: Identifiable, Codable {
    let id: UUID
    var text: String
    let speaker: Speaker
    let timestamp: Date
    let isError: Bool

    /// AI 消息音频数据（TTS 生成，用于重复播放）
    var audioData: Data?
    /// 用户消息录音数据（用户语音输入，用于回放）
    var userVoiceData: Data?
    /// 是否正在播放
    var isPlaying: Bool = false

    init(id: UUID = UUID(), text: String, speaker: Speaker, timestamp: Date = Date(), isError: Bool = false, audioData: Data? = nil, userVoiceData: Data? = nil) {
        self.id = id
        self.text = text
        self.speaker = speaker
        self.timestamp = timestamp
        self.isError = isError
        self.audioData = audioData
        self.userVoiceData = userVoiceData
    }

    enum CodingKeys: String, CodingKey {
        case id, text, speaker, timestamp, isError, audioData, userVoiceData
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        speaker = try container.decode(Speaker.self, forKey: .speaker)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isError = try container.decode(Bool.self, forKey: .isError)
        audioData = try container.decodeIfPresent(Data.self, forKey: .audioData)
        userVoiceData = try container.decodeIfPresent(Data.self, forKey: .userVoiceData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isError, forKey: .isError)
        try container.encode(audioData, forKey: .audioData)
        try container.encode(userVoiceData, forKey: .userVoiceData)
    }
}

enum Speaker: String, Codable {
    case user = "user"
    case ai = "ai"
}
