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
        let systemPrompt = PromptConfig.loadPrompt(for: lessonId)

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
                    let systemPrompt = PromptConfig.loadPrompt(for: lessonId)

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
