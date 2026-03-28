import Foundation
import AVFoundation

class ScoringService {
    static let shared = ScoringService()

    private let apiKey = APIConfig.dashScopeAPIKey
    private let baseURL = APIConfig.dashScopeBaseURL
    private let model = APIConfig.scoringModel
    private let timeoutInterval: TimeInterval = 30

    private init() {}

    // MARK: - Public API

    func scoreConversation(
        messages: [ChatMessage],
        lessonId: Int,
        lessonTitle: String,
        sessionStartTime: Date?
    ) async throws -> ScoreResult {
        // 1. 构建对话文字记录
        let transcript = buildConversationTranscript(from: messages)

        // 2. 拼接所有音频
        let audioData = concatenateAllAudio(from: messages)

        // 3. 构建评分 Prompt
        let scoringPrompt = ScoringPromptConfig.scoringPrompt(
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            conversationTranscript: transcript
        )

        // 4. 构建请求
        let requestBody = buildRequestBody(
            systemPrompt: scoringPrompt,
            transcript: transcript,
            audioData: audioData
        )

        // 5. 发送请求
        let responseJSON = try await sendRequest(body: requestBody)

        // 6. 解析响应
        let stats = computeSessionStats(messages: messages, sessionStartTime: sessionStartTime)
        let result = try parseScoreResponse(responseJSON, lessonId: lessonId, lessonTitle: lessonTitle, stats: stats)

        return result
    }

    // MARK: - Audio Processing

    /// 按对话顺序拼接所有音频（AI audioData + 用户 userVoiceData）
    private func concatenateAllAudio(from messages: [ChatMessage]) -> Data? {
        var pcmChunks: [Data] = []
        let silenceDuration = 0.3 // 秒
        let targetSampleRate = 16000
        let silenceSamples = Int(Double(targetSampleRate) * silenceDuration) // 4800 samples
        let silenceData = Data(count: silenceSamples * 2) // 16-bit = 2 bytes per sample

        for message in messages {
            var audioPCM: Data?

            if message.speaker == .ai, let data = message.audioData {
                // AI 音频是 24kHz WAV（TTS 输出），需要提取 PCM 并降采样到 16kHz
                audioPCM = extractAndResampleAudio(from: data, sourceSampleRate: 24000, targetSampleRate: targetSampleRate)
            } else if message.speaker == .user, let data = message.userVoiceData {
                // 用户音频是 16kHz WAV，提取 PCM
                audioPCM = extractPCMFromWAV(data)
            }

            if let pcm = audioPCM, !pcm.isEmpty {
                if !pcmChunks.isEmpty {
                    pcmChunks.append(silenceData) // 插入静音分隔
                }
                pcmChunks.append(pcm)
            }
        }

        guard !pcmChunks.isEmpty else { return nil }

        var combined = Data()
        for chunk in pcmChunks {
            combined.append(chunk)
        }
        return combined
    }

    /// 从 WAV 数据中提取 PCM 数据（跳过 44 字节头部）
    private func extractPCMFromWAV(_ wavData: Data) -> Data? {
        // 标准 WAV 头部是 44 字节
        guard wavData.count > 44 else { return nil }

        // 验证 RIFF 头
        let riff = String(bytes: wavData[0..<4], encoding: .ascii)
        guard riff == "RIFF" else {
            // 可能已经是纯 PCM 数据
            return wavData
        }

        return wavData[44...]
    }

    /// 提取音频并降采样
    private func extractAndResampleAudio(from data: Data, sourceSampleRate: Int, targetSampleRate: Int) -> Data? {
        guard let pcmData = extractPCMFromWAV(data) else { return nil }

        if sourceSampleRate == targetSampleRate {
            return pcmData
        }

        return resamplePCM(from: pcmData, sourceSampleRate: sourceSampleRate, targetSampleRate: targetSampleRate)
    }

    /// 简单线性降采样（16-bit mono PCM）
    private func resamplePCM(from data: Data, sourceSampleRate: Int, targetSampleRate: Int) -> Data {
        let ratio = Double(sourceSampleRate) / Double(targetSampleRate)
        let sourceCount = data.count / 2 // 16-bit samples
        let targetCount = Int(Double(sourceCount) / ratio)

        var result = Data(capacity: targetCount * 2)

        data.withUnsafeBytes { rawBuffer in
            let sourceBuffer = rawBuffer.bindMemory(to: Int16.self)
            for i in 0..<targetCount {
                let sourceIndex = min(Int(Double(i) * ratio), sourceCount - 1)
                var sample = sourceBuffer[sourceIndex]
                result.append(Data(bytes: &sample, count: 2))
            }
        }

        return result
    }

    // MARK: - Transcript Building

    private func buildConversationTranscript(from messages: [ChatMessage]) -> String {
        var lines: [String] = []
        for (index, message) in messages.enumerated() {
            let speaker = message.speaker == .ai ? "AI (Emii)" : "Student (kiki)"
            let hasAudio = (message.speaker == .ai && message.audioData != nil) ||
                           (message.speaker == .user && message.userVoiceData != nil)
            let audioTag = hasAudio ? " [has audio]" : " [text only]"
            lines.append("[\(index + 1)] \(speaker)\(audioTag): \(message.text)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Request Building

    private func buildRequestBody(systemPrompt: String, transcript: String, audioData: Data?) -> [String: Any] {
        var userContent: [[String: Any]] = []

        // 文字记录
        userContent.append([
            "type": "text",
            "text": "请根据以下对话记录和语音录音进行评分。\n\n对话记录：\n\(transcript)"
        ])

        // 音频（如果有）
        if let audio = audioData {
            let base64Audio = audio.base64EncodedString()
            userContent.append([
                "type": "input_audio",
                "input_audio": [
                    "data": "audio/pcm;rate=16000,\(base64Audio)",
                    "format": "pcm"
                ]
            ])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "temperature": 0.3,
            "max_tokens": 2000
        ]

        return body
    }

    // MARK: - Network

    private func sendRequest(body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: baseURL) else {
            throw ScoringError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        print("[ScoringService] 发送评分请求，数据大小: \(jsonData.count) bytes")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScoringError.networkError("无效的服务器响应")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "未知错误"
            print("[ScoringService] API 错误 \(httpResponse.statusCode): \(errorBody)")
            throw ScoringError.apiError("服务器错误 (\(httpResponse.statusCode))")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScoringError.parseError("无法解析响应 JSON")
        }

        return json
    }

    // MARK: - Response Parsing

    private func parseScoreResponse(_ json: [String: Any], lessonId: Int, lessonTitle: String, stats: SessionStats) throws -> ScoreResult {
        // 提取 content
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ScoringError.parseError("无法提取评分内容")
        }

        print("[ScoringService] 评分响应内容: \(content.prefix(200))...")

        // 提取 JSON（可能包含 markdown 代码块）
        let jsonString = extractJSON(from: content)

        guard let jsonData = jsonString.data(using: .utf8),
              let scoreJSON = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ScoringError.parseError("无法解析评分 JSON")
        }

        // 解析各字段
        let overallScore = scoreJSON["overall_score"] as? Int ?? 75
        let vocabularyScore = scoreJSON["vocabulary_score"] as? Int ?? 75
        let sentencePatternScore = scoreJSON["sentence_pattern_score"] as? Int ?? 75
        let pronunciationScore = scoreJSON["pronunciation_score"] as? Int ?? 75
        let fluencyScore = scoreJSON["fluency_score"] as? Int ?? 75
        let feedback = scoreJSON["feedback"] as? String ?? "表现不错，继续加油！"
        let encouragement = scoreJSON["encouragement"] as? String ?? "你真棒！"
        let correctCount = scoreJSON["correct_count"] as? Int ?? stats.correctCount
        let correctedCount = scoreJSON["corrected_count"] as? Int ?? stats.correctedCount

        // 解析词汇详情
        var vocabularyDetails: [VocabularyScoreDetail] = []
        if let vocabArray = scoreJSON["vocabulary_details"] as? [[String: Any]] {
            for item in vocabArray {
                vocabularyDetails.append(VocabularyScoreDetail(
                    word: item["word"] as? String ?? "",
                    practiced: item["practiced"] as? Bool ?? false,
                    correct: item["correct"] as? Bool ?? false,
                    pronunciationNote: item["pronunciation_note"] as? String
                ))
            }
        }

        // 解析句型详情
        var sentenceDetails: [SentenceScoreDetail] = []
        if let sentArray = scoreJSON["sentence_details"] as? [[String: Any]] {
            for item in sentArray {
                sentenceDetails.append(SentenceScoreDetail(
                    pattern: item["pattern"] as? String ?? "",
                    practiced: item["practiced"] as? Bool ?? false,
                    exampleUsed: item["example_used"] as? String,
                    feedback: item["feedback"] as? String
                ))
            }
        }

        // 使用 API 返回的 correctCount/correctedCount 更新 stats
        let updatedStats = SessionStats(
            totalTurns: stats.totalTurns,
            userTurns: stats.userTurns,
            sessionDuration: stats.sessionDuration,
            vocabularyPracticed: vocabularyDetails.filter { $0.practiced }.count,
            vocabularyTotal: vocabularyDetails.count,
            correctCount: correctCount,
            correctedCount: correctedCount
        )

        return ScoreResult(
            id: UUID(),
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            timestamp: Date(),
            overallScore: overallScore,
            vocabularyScore: vocabularyScore,
            sentencePatternScore: sentencePatternScore,
            pronunciationScore: pronunciationScore,
            fluencyScore: fluencyScore,
            feedback: feedback,
            encouragement: encouragement,
            vocabularyDetails: vocabularyDetails,
            sentenceDetails: sentenceDetails,
            stats: updatedStats
        )
    }

    /// 从可能包含 markdown 代码块的文本中提取 JSON
    private func extractJSON(from text: String) -> String {
        // 尝试提取 ```json ... ``` 代码块
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 尝试提取 ``` ... ``` 代码块
        if let jsonStart = text.range(of: "```"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 尝试找到第一个 { 和最后一个 }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }

    // MARK: - Stats Computation

    private func computeSessionStats(messages: [ChatMessage], sessionStartTime: Date?) -> SessionStats {
        let totalTurns = messages.count
        let userTurns = messages.filter { $0.speaker == .user }.count
        let sessionDuration: Int
        if let start = sessionStartTime {
            sessionDuration = Int(Date().timeIntervalSince(start))
        } else if let first = messages.first {
            sessionDuration = Int(Date().timeIntervalSince(first.timestamp))
        } else {
            sessionDuration = 0
        }

        return SessionStats(
            totalTurns: totalTurns,
            userTurns: userTurns,
            sessionDuration: sessionDuration,
            vocabularyPracticed: 0,
            vocabularyTotal: 0,
            correctCount: 0,
            correctedCount: 0
        )
    }
}

// MARK: - Errors

enum ScoringError: LocalizedError {
    case invalidURL
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case insufficientData(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 API 地址"
        case .networkError(let msg): return "网络错误：\(msg)"
        case .apiError(let msg): return "API 错误：\(msg)"
        case .parseError(let msg): return "解析错误：\(msg)"
        case .insufficientData(let msg): return msg
        }
    }
}
