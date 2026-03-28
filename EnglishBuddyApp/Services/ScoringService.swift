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
        sessionStartTime: Date? = nil
    ) async throws -> ScoreResult {
        print("[ScoringService] 开始评分: \(messages.count) 条消息, lessonId=\(lessonId)")

        // 1. 构建对话文字记录
        let transcript = buildConversationTranscript(from: messages)
        print("[ScoringService] 对话记录:\n\(transcript)")

        // 2. 只拼接学生音频（不包含 AI 音频）
        let audioData = concatenateStudentAudio(from: messages)
        print("[ScoringService] 学生音频数据: \(audioData?.count ?? 0) bytes")

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

        // 6. 解析响应（学习时长基于消息时间戳，不再使用 sessionStartTime）
        let stats = computeSessionStats(messages: messages)
        let result = try parseScoreResponse(responseJSON, lessonId: lessonId, lessonTitle: lessonTitle, stats: stats, messages: messages)

        return result
    }

    // MARK: - Audio Processing

    /// 只拼接学生语音（不包含 AI 音频）
    private func concatenateStudentAudio(from messages: [ChatMessage]) -> Data? {
        var pcmChunks: [Data] = []
        let silenceDuration = 0.3 // 秒
        let targetSampleRate = 16000
        let silenceSamples = Int(Double(targetSampleRate) * silenceDuration)
        let silenceData = Data(count: silenceSamples * 2) // 16-bit = 2 bytes per sample

        for message in messages {
            // 只处理学生消息
            guard message.speaker == .user, let data = message.userVoiceData else { continue }

            // 用户音频是 16kHz WAV，提取 PCM
            if let pcm = extractPCMFromWAV(data), !pcm.isEmpty {
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

    // MARK: - Transcript Building

    private func buildConversationTranscript(from messages: [ChatMessage]) -> String {
        var lines: [String] = []
        var studentIndex = 0
        for (index, message) in messages.enumerated() {
            let hasAudio = (message.speaker == .ai && message.audioData != nil) ||
                           (message.speaker == .user && message.userVoiceData != nil)
            let audioTag = hasAudio ? " [has audio]" : " [text only]"

            if message.speaker == .user {
                // 学生消息额外标注 student_index，供评分模型引用
                lines.append("[\(index + 1)] Student (kiki) [student_index=\(studentIndex)]\(audioTag): \(message.text)")
                studentIndex += 1
            } else {
                lines.append("[\(index + 1)] AI (Emii)\(audioTag): \(message.text)")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Request Building

    private func buildRequestBody(systemPrompt: String, transcript: String, audioData: Data?) -> [String: Any] {
        var userContent: [[String: Any]] = []

        // 文字记录
        userContent.append([
            "type": "text",
            "text": "请根据以下对话记录和学生语音录音进行评分。\n\n说明：语音录音仅包含学生的语音，请据此评价发音准确度和流利度。对话记录包含 AI 教师和学生双方的文字，请据此评价词汇掌握、语法正确性和回答正确性。\n\n对话记录：\n\(transcript)"
        ])

        // 音频（如果有）- 使用 WAV 封装后的 data URL 格式
        if let audio = audioData {
            let wavData = wrapPCMAsWAV(audio, sampleRate: 16000)
            let base64Audio = wavData.base64EncodedString()
            userContent.append([
                "type": "input_audio",
                "input_audio": [
                    "data": "data:audio/wav;base64,\(base64Audio)",
                    "format": "wav"
                ]
            ])
            print("[ScoringService] 学生音频大小: PCM=\(audio.count) WAV=\(wavData.count) base64=\(base64Audio.count)")
        }

        // qwen3-omni-flash 需要 stream=true，且不支持 temperature
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "stream": true,
            "stream_options": ["include_usage": true],
            "max_tokens": 2000
        ]

        return body
    }

    /// 将 PCM 数据封装为 WAV 格式（16-bit mono）
    private func wrapPCMAsWAV(_ pcmData: Data, sampleRate: Int) -> Data {
        let channels: Int = 1
        let bitsPerSample: Int = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = pcmData.count
        let fileSize = 36 + dataSize

        var header = Data()

        // RIFF header
        header.append(contentsOf: "RIFF".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        header.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        header.append(contentsOf: "fmt ".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // chunk size
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // PCM format
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })

        // data chunk
        header.append(contentsOf: "data".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        header.append(pcmData)
        return header
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

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScoringError.networkError("无效的服务器响应")
        }

        guard httpResponse.statusCode == 200 else {
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            let errorBody = String(data: errorData, encoding: .utf8) ?? "未知错误"
            print("[ScoringService] API 错误 \(httpResponse.statusCode): \(errorBody)")
            throw ScoringError.apiError("服务器错误 (\(httpResponse.statusCode))")
        }

        // 收集流式响应，拼接所有 delta content
        var fullContent = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            if jsonStr == "[DONE]" { break }

            guard let chunkData = jsonStr.data(using: .utf8),
                  let chunk = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any],
                  let choices = chunk["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            fullContent += content
        }

        print("[ScoringService] 流式响应收集完成，内容长度: \(fullContent.count)")

        // 构造统一格式返回
        let result: [String: Any] = [
            "choices": [
                ["message": ["content": fullContent]]
            ]
        ]
        return result
    }

    // MARK: - Response Parsing

    private func parseScoreResponse(_ json: [String: Any], lessonId: Int, lessonTitle: String, stats: SessionStats, messages: [ChatMessage]) throws -> ScoreResult {
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
        let grammarScore = scoreJSON["grammar_score"] as? Int ?? 75
        let pronunciationScore = scoreJSON["pronunciation_score"] as? Int ?? 75
        let fluencyScore = scoreJSON["fluency_score"] as? Int ?? 75
        let feedback = scoreJSON["feedback"] as? String ?? "表现不错，继续加油！"
        let encouragement = scoreJSON["encouragement"] as? String ?? "你真棒！"
        let correctCount = scoreJSON["correct_count"] as? Int ?? stats.correctCount
        let correctedCount = scoreJSON["corrected_count"] as? Int ?? stats.correctedCount

        // 构建可评分消息列表（学生消息），用于根据 message_index 查找音频
        let scorableMessages = messages.filter { $0.speaker == .user }

        // 解析词汇详情
        var vocabularyDetails: [VocabularyScoreDetail] = []
        if let vocabArray = scoreJSON["vocabulary_details"] as? [[String: Any]] {
            for item in vocabArray {
                let msgIndex = item["message_index"] as? Int
                var audioData: Data? = nil
                if let idx = msgIndex, idx >= 0, idx < scorableMessages.count {
                    audioData = scorableMessages[idx].userVoiceData
                }
                vocabularyDetails.append(VocabularyScoreDetail(
                    word: item["word"] as? String ?? "",
                    practiced: item["practiced"] as? Bool ?? false,
                    correct: item["correct"] as? Bool ?? false,
                    pronunciationNote: item["pronunciation_note"] as? String,
                    messageIndex: msgIndex,
                    audioData: audioData
                ))
            }
        }

        // 解析语法详情
        var grammarDetails: [GrammarDetail] = []
        if let grammarArray = scoreJSON["grammar_details"] as? [[String: Any]] {
            for item in grammarArray {
                let msgIndex = item["message_index"] as? Int
                var audioData: Data? = nil
                if let idx = msgIndex, idx >= 0, idx < scorableMessages.count {
                    audioData = scorableMessages[idx].userVoiceData
                }
                grammarDetails.append(GrammarDetail(
                    original: item["original"] as? String ?? "",
                    corrected: item["corrected"] as? String,
                    explanation: item["explanation"] as? String,
                    messageIndex: msgIndex,
                    audioData: audioData
                ))
            }
        }

        // 使用 API 返回的 correctCount/correctedCount 更新 stats
        let updatedStats = SessionStats(
            totalTurns: stats.totalTurns,
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
            grammarScore: grammarScore,
            pronunciationScore: pronunciationScore,
            fluencyScore: fluencyScore,
            feedback: feedback,
            encouragement: encouragement,
            vocabularyDetails: vocabularyDetails,
            grammarDetails: grammarDetails,
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

    private func computeSessionStats(messages: [ChatMessage]) -> SessionStats {
        // 对话轮数 = 学生发言次数
        let totalTurns = messages.filter { $0.speaker == .user }.count

        // 学习时长 = 第一条消息到最后一条消息的时间差
        let sessionDuration: Int
        if let first = messages.first, let last = messages.last {
            sessionDuration = Int(last.timestamp.timeIntervalSince(first.timestamp))
        } else {
            sessionDuration = 0
        }

        return SessionStats(
            totalTurns: totalTurns,
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
