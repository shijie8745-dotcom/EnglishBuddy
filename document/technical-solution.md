# EnglishBuddy 技术方案文档

## 1. 架构设计

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  (CourseListView, ChatView, AIChatTestView, etc.)   │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                 ViewModels                           │
│  (@Observable: CourseViewModel, ChatViewModel)      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                  Services                            │
│  (AIChatService, TTSService, DataStore)             │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                   Models                             │
│  (User, Pet, Lesson, ChatMessage, CheckInRecord)    │
└─────────────────────────────────────────────────────┘
```

### 1.2 MVVM 实现方式

采用 Swift 6 的 `@Observable` 宏实现响应式数据绑定：

```swift
// Model
class User: Codable {
    var name: String
    var currentPracticeLessonId: Int?
}

// ViewModel
@Observable
class CourseViewModel {
    var user: User
    var lessons: [Lesson]
    var pet: Pet
}

// View
struct CourseListView: View {
    @State private var viewModel = CourseViewModel()
    // 自动响应 viewModel 的变化
}
```

## 2. 数据模型设计

### 2.1 核心模型关系

```
User
├── currentPracticeLessonId → Lesson?
├── checkInRecords: [CheckInRecord]
├── currentCarrots: Int
└── totalCarrots: Int

Pet
├── name: String (default: "xixi")
├── level: Int
├── experience: Int
├── totalFed: Int
└── positionX/Y: CGFloat (拖动位置)

Lesson
├── id: Int
├── title: String
├── vocabulary: [VocabularyItem]
└── sentencePatterns: [SentencePattern]

ChatMessage
├── text: String
├── speaker: Speaker (.user / .ai)
├── audioData: Data? (TTS 缓存)
└── userVoiceData: Data? (录音缓存)
```

### 2.2 数据持久化方案

使用 UserDefaults + JSON 编码：

```swift
class DataStore {
    static func loadUser() -> User {
        guard let data = defaults.data(forKey: "user"),
              let user = try? JSONDecoder().decode(User.self, from: data)
        else { return User() }
        return user
    }

    func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: "user")
        }
    }
}
```

**存储键值**:
- `user` - 用户信息
- `pet` - 宠物数据
- `progress` - 学习进度
- `companion` - 旧版伴侣数据（已弃用）

## 3. AI 对话实现

### 3.1 多轮对话技术方案

**消息格式** (OpenAI 兼容):
```json
{
  "model": "qwen2.5-7b-instruct",
  "messages": [
    {"role": "system", "content": "系统 Prompt..."},
    {"role": "user", "content": "你好"},
    {"role": "assistant", "content": "Hello! Nice to meet you!"},
    {"role": "user", "content": "今天天气怎么样"}
  ]
}
```

**角色映射**:
- `Speaker.user` → `"user"`
- `Speaker.ai` → `"assistant"`

**实现代码**:
```swift
func sendMessage(
    _ message: String,
    lessonId: Int,
    historyMessages: [ChatMessage] = []
) async throws -> String {
    var messagesArray: [[String: String]] = [
        ["role": "system", "content": systemPrompt]
    ]

    // 添加历史消息
    for chatMessage in historyMessages {
        let role = chatMessage.speaker == .user ? "user" : "assistant"
        messagesArray.append(["role": role, "content": chatMessage.text])
    }

    // 添加当前消息
    messagesArray.append(["role": "user", "content": message])

    // 发送请求...
}
```

### 3.2 课程相关 Prompt 加载

**PromptConfig** (本地配置):
```swift
struct PromptConfig {
    static func loadPrompt(for lessonId: Int) -> String {
        // 根据课程 ID 加载对应的 Prompt
        // 包含课程标题、词汇、句型等信息
    }
}
```

**Prompt 结构**:
```
你是 Amy，一位耐心的英语外教...

当前课程信息：
- 标题：[课程标题]
- 词汇：[词汇列表]
- 句型：[句型列表]

请根据以上内容与学生对话...
```

### 3.3 TTS (文本转语音)

**阿里云 qwen3-TTS-Instruct-Flash**:
```swift
func speak(_ text: String, for messageId: UUID) async -> Data? {
    let requestBody: [String: Any] = [
        "model": "qwen3-TTS-Instruct-Flash",
        "input": text,
        "instructions": "采用标准英式英语，吐字清晰，语速较慢..."
    ]
    // 请求并返回音频数据
}
```

**iOS 系统 TTS** (AI 测试页面使用，节省费用):
```swift
let synthesizer = AVSpeechSynthesizer()
let utterance = AVSpeechUtterance(string: text)
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
utterance.rate = 0.5
synthesizer.speak(utterance)
```

## 4. 语音识别实现

### 4.1 Speech Framework 封装

```swift
class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    func startRecording() throws {
        // 配置音频会话
        // 创建语音识别请求
        // 开始识别
    }

    func stopRecording() -> String {
        // 停止识别
        // 返回最终文本
    }
}
```

### 4.2 录音数据处理

```swift
AudioRecorder → PCM Data → Speech Recognition → Text
                     ↓
              userVoiceData (保存到 ChatMessage)
```

## 5. 游戏化系统实现

### 5.1 宠物升级算法

```swift
class Pet {
    var level: Int = 1
    var experience: Int = 0

    var levelUpThreshold: Int { level * 100 }

    func gainExperience(_ amount: Int) {
        experience += amount
        while experience >= levelUpThreshold {
            experience -= levelUpThreshold
            level += 1
        }
    }

    func feed() {
        totalFed += 1
        gainExperience(50)  // 每次喂食 +50 经验
    }
}
```

### 5.2 签到连续天数计算

```swift
func calculateConsecutiveDays() -> Int {
    let calendar = Calendar.current
    let sortedRecords = user.checkInRecords.sorted { $0.date < $1.date }

    var consecutive = 0
    var checkDate = calendar.startOfDay(for: Date())

    for record in sortedRecords.reversed() {
        let recordDate = calendar.startOfDay(for: record.date)
        if calendar.isDate(recordDate, inSameDayAs: checkDate) {
            consecutive += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else if recordDate < checkDate {
            break
        }
    }
    return consecutive
}
```

### 5.3 胡萝卜奖励规则

```swift
checkIn() -> Int {
    let consecutive = consecutiveDays
    var earned = CheckInReward.daily  // 5 个

    if consecutive >= 6 {  // 第 7 天
        earned += CheckInReward.consecutive7Days  // +10
    } else if consecutive >= 2 {  // 第 3 天
        earned += CheckInReward.consecutive3Days  // +5
    }

    user.currentCarrots += earned
    user.totalCarrots += earned
    return earned
}
```

## 6. UI 组件设计

### 6.1 ViewModifiers 和组件复用

```swift
// 主色渐变
extension View {
    func primaryGradient() -> some View {
        self.background(
            LinearGradient(
                colors: [Color(hex: "F97316"), Color(hex: "FB923C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// 卡片样式
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
    }
}
```

### 6.2 宠物拖动实现

```swift
struct PetView: View {
    @State private var position: CGPoint
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        petImage
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        position.x += value.translation.width
                        position.y += value.translation.height
                        // 保存位置到 UserDefaults
                        viewModel.updatePetPosition(x: position.x, y: position.y)
                    }
            )
    }
}
```

## 7. 网络层设计

### 7.1 API 请求封装

```swift
class AIChatService {
    static let shared = AIChatService()

    private let apiKey = APIConfig.dashScopeAPIKey
    private let baseURL = APIConfig.dashScopeBaseURL
    private let model = APIConfig.chatModel

    func sendMessage(
        _ message: String,
        lessonId: Int,
        historyMessages: [ChatMessage] = []
    ) async throws -> String {
        // 构建请求
        // 发送请求
        // 解析响应
        // 错误处理
    }
}
```

### 7.2 错误处理策略

```swift
enum AIChatError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
}

// 使用降级响应
do {
    let response = try await AIChatService.shared.sendMessage(...)
} catch {
    // 返回友好的默认响应
    return "Sorry, I'm having trouble connecting. Please try again!"
}
```

## 8. 安全与隐私

### 8.1 敏感信息保护

**不提交到 Git 的文件**:
- `Config/APIConfig.swift` - API 密钥
- `Config/PromptConfig.swift` - Prompt 内容、学生信息

**配置方式**:
```swift
// APIConfig.swift.example (提交到 Git)
struct APIConfig {
    static let dashScopeAPIKey = "YOUR_API_KEY_HERE"
}

// APIConfig.swift (本地创建，gitignored)
struct APIConfig {
    static let dashScopeAPIKey = "sk-xxxxxxxxxxxx"
}
```

### 8.2 数据传输安全

- 使用 HTTPS 进行 API 通信
- API Key 存储在本地，不硬编码
- 用户隐私数据（录音）仅本地存储

## 9. 性能优化

### 9.1 异步加载

```swift
// AI 响应异步处理
Task {
    await getAIResponse(to: text)
}

// TTS 后台生成
Task {
    if let audioData = await TTSService.shared.speak(text, for: message.id) {
        // 保存音频数据
    }
}
```

### 9.2 图片/音频缓存

```swift
struct ChatMessage {
    var audioData: Data?  // TTS 音频缓存
    var userVoiceData: Data?  // 用户录音缓存
}
```

### 9.3 LazyVStack 优化长列表

```swift
LazyVStack(spacing: 12) {
    ForEach(viewModel.lessons) { lesson in
        LessonRow(lesson: lesson)
    }
}
```

## 10. 开发规范

### 10.1 代码组织

```
EnglishBuddyApp/
├── Models/          # 数据模型
├── Views/           # SwiftUI 视图
├── ViewModels/      # 业务逻辑
├── Services/        # 网络服务、TTS等
├── Utils/           # 工具类、扩展
├── Extensions/      # Swift 扩展
├── Config/          # 配置文件 (gitignored)
└── Resources/       # 资源文件
```

### 10.2 Git 工作流

1. **本地分支开发**:
   ```bash
   git checkout -b feature/xxx
   ```

2. **本地验证后推送**:
   ```bash
   git add .
   git commit -m "..."
   git push origin feature/xxx
   ```

3. **创建 PR 合并到 main**

### 10.3 命名规范

- **文件**: 大驼峰命名 `CourseListView.swift`
- **变量**: 小驼峰命名 `currentLesson`
- **常量**: 大写下划线 `CHECK_IN_DAILY_REWARD`
- **ViewModel**: 后缀 `ViewModel` `CourseViewModel`

## 11. 附录

### 11.1 第三方依赖

- **Speech Framework**: 语音识别 (系统框架)
- **AVFoundation**: TTS 播放 (系统框架)
- **Observation**: 状态管理 (Swift 6 原生)

### 11.2 外部服务

| 服务 | 用途 | 配置项 |
|------|------|--------|
| 阿里云 DashScope | AI 对话 | API Key, Model |
| 阿里云 TTS | 语音合成 | API Key |

### 11.3 更新记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-18 | 1.0 | 添加多轮对话技术方案 |
| 2026-03-08 | 0.5 | 初始版本 |
