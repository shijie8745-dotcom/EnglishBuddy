import Foundation

class AIChatService {
    static let shared = AIChatService()

    private var user: User { DataStore.loadUser() }

    // 临时使用硬编码的 API Key（确保正确）
    private let apiKey: String = "sk-638ec91a361f4c4abd386ea346f51c14"

    private let model = "qwen3.5-plus"

    // 使用 OpenAI 兼容模式调用 DashScope API
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"

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
class SystemPromptLoader {
    static func load(for lessonId: Int) -> String {
        let prompts: [Int: String] = [
            0: promptForUnit0(),
            1: promptForUnit1(),
            2: promptForUnit2(),
            3: promptForUnit3(),
            4: promptForUnit4(),
            5: promptForUnit5(),
            6: promptForUnit6(),
            7: promptForUnit7(),
            8: promptForUnit8(),
            9: promptForUnit9()
        ]
        return prompts[lessonId] ?? promptForUnit0()
    }

    private static func basePrompt(unitTitle: String, unitDesc: String, vocabulary: String, patterns: String) -> String {
        return """
#角色
你是儿童英语外教Ian，擅长用有亲和力的语气和专业的教学方式提升儿童的英文口语水平
##性格特点##
- 耐心、语速较慢
- 热情友好，善于引导

#目标
现在需要你和学生进行英语口语练习，开始对话时用简单的方式打招呼（不要超过1句话），然后自然引导进入**课程信息**练习

#课程信息
**当前课程**：\(unitTitle) - \(unitDesc)
**核心词汇**：\(vocabulary)
**核心句型**：\(patterns)

#学生信息
- 姓名：kiki
- 年龄：6岁
- 性别：女
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

    private static func promptForUnit0() -> String {
        return basePrompt(
            unitTitle: "Unit 0 - Hello",
            unitDesc: "打招呼和认识新朋友",
            vocabulary: "red, blue, green, yellow, orange, pink, purple, brown, black, white, grey, one, two, three, four, five, six, seven, eight, nine, ten",
            patterns: "What's your name? I'm... / How old are you? I'm... / I like..."
        )
    }

    private static func promptForUnit1() -> String {
        return basePrompt(
            unitTitle: "Unit 1 - Our new school",
            unitDesc: "我们的新学校",
            vocabulary: "pencil, rubber, crayon, bag, chair, book, pen, pencil case, desk, teacher, classroom, door, window, wall, board, ruler, bookcase, cupboard, paper, playground",
            patterns: "What's this? It's a... / Where is...? It's on/in/under/next to... / Do you have...? Yes, I do. / No, I don't."
        )
    }

    private static func promptForUnit2() -> String {
        return basePrompt(
            unitTitle: "Unit 2 - All about us",
            unitDesc: "关于我们",
            vocabulary: "family, mum, dad, sister, brother, baby, head, eyes, ears, nose, mouth, hair, brown, green, blue, black, blonde",
            patterns: "Who is she/he? She's/He's my... / Have you got...? Yes, I have. / No, I haven't."
        )
    }

    private static func promptForUnit3() -> String {
        return basePrompt(
            unitTitle: "Unit 3 - Fun on the farm",
            unitDesc: "农场的乐趣",
            vocabulary: "cat, dog, chicken, cow, horse, sheep, small, big, long, short",
            patterns: "It's a [adjective] [noun]. / Has it got...? Yes, it has. / No, it hasn't."
        )
    }

    private static func promptForUnit4() -> String {
        return basePrompt(
            unitTitle: "Unit 4 - Food with friends",
            unitDesc: "与朋友分享食物",
            vocabulary: "apple, banana, orange, pear, carrot, chocolate, chicken, eggs, water, juice, like, don't like",
            patterns: "Do you like...? Yes, I do. / No, I don't. / Would you like...? Yes, please. / No, thank you."
        )
    }

    private static func promptForUnit5() -> String {
        return basePrompt(
            unitTitle: "Unit 5 - Happy birthday",
            unitDesc: "生日快乐",
            vocabulary: "January, February, March, April, May, June, July, August, September, October, November, December, ball, bike, kite, robot, teddy, toy car",
            patterns: "When is your birthday? It's in [month]. / Whose...? It's my/your/his/her... / I want..."
        )
    }

    private static func promptForUnit6() -> String {
        return basePrompt(
            unitTitle: "Unit 6 - A day out",
            unitDesc: "外出游玩",
            vocabulary: "zoo, park, beach, mountain, bus, car, bike, helicopter, crocodile, elephant, giraffe, hippo",
            patterns: "There is/are... / Is there...? / Are there...? / Let's... / By [transport]"
        )
    }

    private static func promptForUnit7() -> String {
        return basePrompt(
            unitTitle: "Unit 7 - Let's play",
            unitDesc: "一起玩耍",
            vocabulary: "football, basketball, tennis, swim, run, jump, walk, sing, dance, play, ride, fly",
            patterns: "What are you doing? I'm [verb+ing]. / Can you...? Yes, I can. / No, I can't. / Let's..."
        )
    }

    private static func promptForUnit8() -> String {
        return basePrompt(
            unitTitle: "Unit 8 - At home",
            unitDesc: "在家里",
            vocabulary: "house, living room, bedroom, kitchen, bathroom, garden, TV, bed, table, sofa, cupboard, mat",
            patterns: "Where is the [furniture]? It's in the [room]. / Can you...?"
        )
    }

    private static func promptForUnit9() -> String {
        return basePrompt(
            unitTitle: "Unit 9 - Happy holidays",
            unitDesc: "节日快乐（综合复习课）",
            vocabulary: "hot, cold, sunny, rainy, snowy, windy, spring, summer, autumn, winter, happy, sad, tired, hungry",
            patterns: "How's the weather? / I like/enjoy [verb+ing]. / Me too! / How do you feel?"
        ) + "\n\n这是综合复习课，请综合运用 Units 0-8 的所有内容与学生练习。"
    }
}
