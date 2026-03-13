import Foundation

class AIChatService {
    static let shared = AIChatService()

    private var user: User { DataStore.loadUser() }

    // 使用 APIConfig 中的配置
    private let apiKey: String = APIConfig.dashScopeAPIKey
    private let model = APIConfig.chatModel
    private let baseURL = APIConfig.dashScopeBaseURL

    private init() {}

    func sendMessage(_ message: String, lessonId: Int) async throws -> String {
        let systemPrompt = SystemPromptLoader.load(for: lessonId)

        // OpenAI 兼容格式
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": message]
            ],
            "temperature": 0.7,
            "max_tokens": 200,
            "enable_thinking": false
        ]

        guard let url = URL(string: baseURL) else {
            print("[AIChatService] 错误: 无效的URL")
            throw AIChatError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 阿里云 DashScope 使用 Authorization: Bearer <api-key> 格式
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let finalKey = apiKey
        print("[AIChatService] 使用的 API Key: \(finalKey)")
        print("[AIChatService] 用户设置的 API Key: '\(user.apiKey)' (长度: \(user.apiKey.count))")
        print("[AIChatService] Authorization Header: Bearer \(finalKey.prefix(15))...")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("[AIChatService] 发送请求到: \(baseURL)")
        print("[AIChatService] 请求体: \(requestBody)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[AIChatService] 错误: 无法转换为HTTPURLResponse")
            throw AIChatError.invalidResponse
        }

        print("[AIChatService] 响应状态码: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "无法读取响应"
            print("[AIChatService] 错误: 非200状态码, 响应: \(responseString)")
            throw AIChatError.invalidResponse
        }

        let responseString = String(data: data, encoding: .utf8) ?? "无法读取响应"
        print("[AIChatService] 原始响应: \(responseString)")

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[AIChatService] 错误: 无法解析JSON")
            throw AIChatError.decodingError
        }

        print("[AIChatService] 解析后的JSON: \(json)")

        // OpenAI 兼容格式: choices 在根级别
        if let choices = json["choices"] as? [[String: Any]], let first = choices.first {
            print("[AIChatService] 找到 choices 数组")

            // OpenAI 格式: message.content
            if let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                print("[AIChatService] 成功提取内容")
                return content
            }

            // 备用: delta.content (流式响应的格式)
            if let delta = first["delta"] as? [String: Any],
               let content = delta["content"] as? String {
                print("[AIChatService] 成功提取内容(delta)")
                return content
            }
        }

        // 错误信息
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("[AIChatService] 错误: API 返回错误: \(message)")
        }

        print("[AIChatService] 错误: 无法从响应中提取内容")
        print("[AIChatService] JSON结构: \(json.keys)")
        throw AIChatError.decodingError
    }

    // Stream mode for receiving chunks
    func streamMessage(_ message: String, lessonId: Int) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                do {
                    let systemPrompt = SystemPromptLoader.load(for: lessonId)

                    // OpenAI 兼容格式
                    let requestBody: [String: Any] = [
                        "model": model,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": message]
                        ],
                        "temperature": 0.7,
                        "max_tokens": 200,
                        "stream": true,
                        "enable_thinking": false
                    ]

                    guard let url = URL(string: baseURL) else {
                        throw AIChatError.invalidURL
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw AIChatError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }

                        let dataStr = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)

                        if dataStr == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = dataStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let first = choices.first,
                              let delta = first["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch {
                    continuation.yield("Sorry, I'm having trouble connecting. Please try again!")
                    continuation.finish()
                }
            }
        }
    }
}

enum AIChatError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
}

// MARK: - System Prompt Loader
/// 从本地JSON文件加载系统Prompt
/// Prompts.json 文件包含敏感的教学内容，不应提交到GitHub
class SystemPromptLoader {
    private static let studentName = "kiki"
    private static let studentAge = "6"
    private static let studentGender = "女"

    static func load(for lessonId: Int) -> String {
        guard let promptsData = loadPromptsFromJSON(),
              let units = promptsData["units"] as? [String: [String: String]],
              let unitData = units[String(lessonId)] ?? units["0"] else {
            print("[SystemPromptLoader] 无法加载Prompt数据，返回默认Prompt")
            return defaultPrompt()
        }

        let baseTemplate = (promptsData["baseTemplate"] as? String) ?? defaultBaseTemplate()

        var prompt = baseTemplate
            .replacingOccurrences(of: "{{unitTitle}}", with: unitData["title"] ?? "")
            .replacingOccurrences(of: "{{unitDesc}}", with: unitData["description"] ?? "")
            .replacingOccurrences(of: "{{vocabulary}}", with: unitData["vocabulary"] ?? "")
            .replacingOccurrences(of: "{{patterns}}", with: unitData["patterns"] ?? "")
            .replacingOccurrences(of: "{{studentName}}", with: studentName)
            .replacingOccurrences(of: "{{studentAge}}", with: studentAge)
            .replacingOccurrences(of: "{{studentGender}}", with: studentGender)

        // 添加额外内容（如复习课的特殊说明）
        if let extra = unitData["extra"] {
            prompt += extra
        }

        return prompt
    }

    private static func loadPromptsFromJSON() -> [String: Any]? {
        // 尝试多种路径查找Prompts.json
        let possiblePaths = [
            Bundle.main.path(forResource: "Prompts", ofType: "json", inDirectory: "Config"),
            Bundle.main.path(forResource: "Prompts", ofType: "json"),
            Bundle.main.bundlePath + "/Config/Prompts.json",
            Bundle.main.bundlePath + "/Prompts.json"
        ]

        for path in possiblePaths {
            guard let path = path,
                  FileManager.default.fileExists(atPath: path),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            print("[SystemPromptLoader] 成功从 \(path) 加载Prompts.json")
            return json
        }

        print("[SystemPromptLoader] 无法找到或解析 Prompts.json")
        return nil
    }

    private static func defaultPrompt() -> String {
        return defaultBaseTemplate()
            .replacingOccurrences(of: "{{unitTitle}}", with: "Unit 0 - Hello")
            .replacingOccurrences(of: "{{unitDesc}}", with: "打招呼和认识新朋友")
            .replacingOccurrences(of: "{{vocabulary}}", with: "hello, name, nice, meet")
            .replacingOccurrences(of: "{{patterns}}", with: "What's your name? I'm...")
            .replacingOccurrences(of: "{{studentName}}", with: studentName)
            .replacingOccurrences(of: "{{studentAge}}", with: studentAge)
            .replacingOccurrences(of: "{{studentGender}}", with: studentGender)
    }

    private static func defaultBaseTemplate() -> String {
        return """
#角色
你是儿童英语外教Ian，擅长用有亲和力的语气和专业的教学方式提升儿童的英文口语水平
##性格特点##
- 耐心、语速较慢
- 热情友好，善于引导

#目标
现在需要你和学生进行英语口语练习，开始对话时用简单的方式打招呼（不要超过1句话），然后自然引导进入**课程信息**练习

#课程信息
**当前课程**：{{unitTitle}} - {{unitDesc}}
**核心词汇**：{{vocabulary}}
**核心句型**：{{patterns}}

#学生信息
- 姓名：{{studentName}}
- 年龄：{{studentAge}}岁
- 性别：{{studentGender}}
- 英语水平：初级，词汇量较少、语法不熟悉，只能进行非常简单的口语表达，可能会有语法或表达错误
- 性格：比较内向，害怕说错，可能会不敢表达

#教学规则
1. 使用匹配学生英文水平的简单英语
2. 你虽然是教师，但本次对话必须模拟日常生活对话，不要用教师的口吻
3. 不要让学生复述单词或句子，要引导学生自主对话（发音错误纠正除外）
4. 如果学生说中文，用英文重复并引导用英文继续对话
5. 如果回答错误，温和的纠正学生的错误，并给予一些鼓励
6. 如果学生发音错误，需要明确告知发音问题，自然地重复正确的说法，并让学生复述
7. 如果提问需要让学生回答物品，可使用emoji表情，其他时候不要使用emoji
8. 如果学生讲的话偏离课程，可以先做简单回答，然后引导回到课程相关内容
9. 如果学生回答的太简单，可以引导学生按完整句式回答，
    example.教师问题：Do you have a crayon?学生回答：Yes，此时学生回答太短，教师可以通过引导让学生回答：Yes,I do，尽量使用简单的英语进行引导
10. 每次回复控制不超过2句话
11. 始终用英语回复
12. 不要尝试用肢体语言、旁白或描述自己的动作，只需要进行正常对话内容
13. 标点符号只能使用','、'.'、'!'、'?'，不要使用其他标点符号

#语音识别提示
- 用户通过语音输入，可能因为发音不标准导致识别结果奇怪或为空
- 如果用户消息不清晰、过短，请温柔地说："I didn't hear you clearly. Can you say that again?"
"""
    }
}
