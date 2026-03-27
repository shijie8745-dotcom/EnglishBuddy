# EnglishBuddy 技术方案文档

## 1. 架构设计

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Views                     │
│  (CourseListView, ChatView, CloudShopView, etc.)    │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                 ViewModels                           │
│  (@Observable: CourseViewModel, ChatViewModel,      │
│   CloudShopViewModel)                               │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                  Services                            │
│  (AIChatService, TTSService, AliyunASRService,      │
│   DataStore, LessonResourceManager)                 │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                   Models                             │
│  (User, PetCollection, Lesson, ChatMessage,         │
│   CloudCoinSystem)                                  │
└─────────────────────────────────────────────────────┘
```

### 1.2 MVVM 实现方式

采用 Swift 6 的 `@Observable` 宏实现响应式数据绑定：

```swift
// Model
class User: Codable {
    var name: String
    var currentPracticeLessonId: Int?
    var petCollection: PetCollection
    var cloudCoinSystem: CloudCoinSystem
}

// ViewModel
@Observable
class CourseViewModel {
    var user: User
    var lessons: [Lesson]
    var progress: [LessonProgress]
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
├── petCollection: PetCollection
│   ├── currentPetId: String
│   └── unlockedPets: [String: UnlockedPetInfo]
├── cloudCoinSystem: CloudCoinSystem
│   ├── coins: Int
│   ├── totalEarned: Int
│   ├── checkInRecords: [CheckInRecord]
│   ├── todayChatCount: Int
│   └── totalChatCount: Int
├── totalStudyTime: Int
└── totalSessions: Int

PetCollection
├── currentPetId: String
├── unlockedPets: [String: UnlockedPetInfo]
├── currentPet: PetDefinition?
└── allPetsSorted: [PetDefinition]

PetDefinition
├── id: String
├── name: String
└── imageName: String

Lesson
├── id: Int
├── title: String
├── unitTitle: String
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
    static let shared = DataStore()

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
- `user` - 用户信息（含 petCollection, cloudCoinSystem）
- `progress` - 学习进度
- `userAvatar` - 用户头像数据
- `chatHistory` - 对话历史记录（按 unit 存储）

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

### 3.2 TTS (文本转语音)

#### 3.2.1 流式 TTS（主要方案）

**模型**: `qwen3-tts-instruct-flash-realtime` (阿里云 DashScope)

**连接方式**: WebSocket
```
wss://dashscope.aliyuncs.com/api-ws/v1/realtime?model=qwen3-tts-instruct-flash-realtime
```

**核心实现**:
```swift
class QwenTTSRealtimeService {
    var webSocketTask: URLSessionWebSocketTask?
    var playerNode: AVAudioPlayerNode?
    var onAudioChunk: ((Data) -> Void)?      // 收到音频块回调
    var onComplete: ((Data) -> Void)?         // 音频数据接收完成

    func connect() async throws               // 建立 WebSocket 连接
    func updateSession(voice: String) async   // 配置会话参数
    func appendText(_ text: String) async     // 发送文本
    func finish()                             // 结束会话
}
```

**音频参数**:
- 采样率: 24000 Hz
- 格式: PCM 16-bit Mono
- 编码: Base64 (传输) → WAV (缓存)

**工作流程**:
```
1. 建立 WebSocket 连接
2. 发送 session.update 配置（voice, mode, sample_rate）
3. 发送 input_text_buffer.append 文本
4. 接收 response.audio.delta 音频块（边收边播）
5. 收到 session.finished 结束
6. 音频时长计算后触发播放完成
```

**性能指标**:
| 指标 | 值 |
|------|-----|
| 首字延迟 | ~0.3s |
| 语音同步 | 动画与播放时长同步 |
| 缓存格式 | WAV (支持重播) |

#### 3.2.2 非流式 TTS（降级方案）

**模型**: `cosyvoice-v2`

**请求方式**: HTTP REST

```swift
func speak(_ text: String, for messageId: UUID) async -> Data? {
    let requestBody: [String: Any] = [
        "model": "cosyvoice-v2",
        "input": ["text": text, "voice": "longxiaochun"],
        "stream": false
    ]
    // 返回完整 WAV 音频数据
}
```

**播放管理**:
```swift
class TTSService {
    var isSpeaking: Bool
    var currentPlayingMessageId: UUID?

    func playFromCache(_ data: Data, for messageId: UUID)
    func stop()
}
```

#### 3.2.3 音频会话管理

**问题背景**: TTS 和 ASR 需要共享音频会话，iOS 音频会话类别切换不可靠。

**解决方案**: TTS 和 ASR 统一使用 `playAndRecord` 模式

```swift
// TTS 和 ASR 共用相同的音频会话配置
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
```

**优势**:
| 对比项 | 之前（切换模式） | 之后（统一模式） |
|--------|-----------------|-----------------|
| 模式切换 | playback ↔ playAndRecord | 无需切换 |
| 切换延迟 | ~0.4秒 | ~0.1秒 |
| 可靠性 | 不可靠 | 稳定 |
| 录音打断播放 | 可能冲突 | 无冲突 |

#### 3.2.4 竞态条件处理

**WebSocket 任务引用检查**:

```swift
// 问题：旧任务的回调可能在新任务运行时触发
// 解决：使用 === 比较任务引用

private func startReceiving() {
    let currentTask = webSocketTask  // 捕获当前引用
    currentTask?.receive { [weak self] result in
        guard self?.webSocketTask === currentTask else {
            print("忽略旧任务的接收回调")
            return
        }
        // 处理消息...
    }
}

// 委托方法也需要检查
func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    guard webSocketTask === self.webSocketTask else {
        print("忽略旧任务的连接打开回调")
        return
    }
    // 处理连接...
}
```

**重置连接时的顺序问题**:

```swift
func reset() {
    let taskToClose = webSocketTask  // 先保存引用
    connectionContinuation = nil      // 清理 continuation
    webSocketTask = nil               // 清理引用
    // ... 重置其他状态 ...
    taskToClose?.cancel()             // 最后关闭旧连接
}
```

#### 3.2.5 录音优先级机制

**问题**: 用户在 TTS 播放时录音，导致 ASR 识别不准或无声音。

**解决方案**: 用户录音操作优先级最高，强制停止 TTS

```swift
// SpeechRecognizer.startRecording()
func startRecording() throws {
    // 1. 停止 TTS 播放
    if QwenTTSRealtimeService.shared.isPlaying {
        QwenTTSRealtimeService.shared.stop()
    }

    // 2. 等待音频引擎停止（无需等待音频会话切换）
    Thread.sleep(forTimeInterval: 0.1)

    // 3. 开始录音（音频会话已是 playAndRecord）
    try asrService.startRecording()
}

// ChatViewModel.stopAllPlayback()
func stopAllPlayback() {
    QwenTTSRealtimeService.shared.stop()
    TTSService.shared.stop()
    currentlyPlayingMessageId = nil
    streamingPlayingMessageId = nil
    // 清除所有消息的播放状态
    for index in messages.indices {
        messages[index].isPlaying = false
    }
}
```

#### 3.2.6 超时回退机制

**问题**: 流式 TTS 偶发性超时，服务器不返回音频。

**解决方案**: 10 秒超时后自动回退到非流式 TTS

```swift
let audioComplete = AsyncStream<Bool?> { continuation in
    var isFinished = false

    QwenTTSRealtimeService.shared.onComplete = { audioData in
        guard !isFinished else { return }
        isFinished = true
        // 保存音频并完成
        continuation.yield(true)
        continuation.finish()
    }

    QwenTTSRealtimeService.shared.onError = { error in
        guard !isFinished else { return }
        isFinished = true
        continuation.yield(false)
        continuation.finish()
    }

    // 超时机制
    Task {
        try? await Task.sleep(nanoseconds: 10_000_000_000)  // 10 秒
        if !isFinished {
            isFinished = true
            continuation.yield(nil)  // 超时信号
            continuation.finish()
        }
    }
}

// 处理结果
if result == true {
    print("流式 TTS 完成")
} else {
    // 回退到非流式 TTS
    await addAIMessageWithNonStreamingTTS(text, messageId: messageId)
}
```

## 4. 语音识别实现

### 4.1 阿里云 ASR 实时语音识别

**WebSocket 连接**:
```swift
class AliyunASRService {
    var webSocket: URLSessionWebSocketTask?
    var transcript: String = ""
    var isReady: Bool = false

    func prepare() async {
        // 预连接 WebSocket
    }

    func startRecording() {
        // 发送音频数据流
    }

    func stopRecording() -> String {
        // 发送结束信号，返回最终文本
    }

    func cancelRecording() {
        // 取消录音（不发送识别结果）
    }
}
```

**音频数据格式**:
- 采样率: 16000 Hz
- 格式: PCM
- 位深: 16-bit

### 4.2 连接优化

```swift
// 预连接：进入对话页时提前建立连接
func prepareRecording() {
    Task {
        await AliyunASRService.shared.prepare()
    }
}
```

## 5. 云朵币系统实现

### 5.1 奖励计算

```swift
class CloudCoinSystem {
    var coins: Int
    var totalEarned: Int
    var checkInRecords: [CheckInRecord]
    var todayChatCount: Int
    var totalChatCount: Int

    // 学习奖励：1分钟 = 1币
    func earnCoinsFromStudy(minutes: Int) -> Int {
        let earned = minutes
        coins += earned
        totalEarned += earned
        return earned
    }

    // 打卡奖励
    func performCheckIn() -> Int {
        guard canCheckIn else { return 0 }  // 今日未打卡且对话>=10次

        var earned = CloudCoinReward.daily  // 5币
        let consecutive = calculateConsecutiveDays()

        if consecutive >= 6 {
            earned += CloudCoinReward.consecutive7Days  // +10币
        } else if consecutive >= 2 {
            earned += CloudCoinReward.consecutive3Days  // +5币
        }

        coins += earned
        totalEarned += earned
        checkInRecords.append(CheckInRecord(...))
        return earned
    }
}
```

### 5.2 学习时长计算

```swift
func finishSession() {
    if let startTime = sessionStartTime {
        let totalSeconds = Date().timeIntervalSince(startTime)
        let fullMinutes = Int(totalSeconds) / 60
        let remainingSeconds = Int(totalSeconds) % 60

        // >30秒算1分钟
        let studyMinutes = remainingSeconds >= 30
            ? fullMinutes + 1
            : fullMinutes

        if studyMinutes > 0 {
            user.totalStudyTime += studyMinutes
            user.cloudCoinSystem.earnCoinsFromStudy(minutes: studyMinutes)
        }
    }
}
```

## 6. 响应式布局实现

### 6.1 Size Class 检测

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
private var isCompact: Bool { horizontalSizeClass == .compact }
```

### 6.2 AdaptiveLayout 工具类

```swift
enum AdaptiveLayout {
    enum Dimensions {
        static func floatingPetSize(isCompact: Bool) -> CGFloat {
            isCompact ? 140 : 250
        }

        static func statIconSize(isCompact: Bool) -> CGFloat {
            isCompact ? 40 : 48
        }

        static func horizontalPadding(isCompact: Bool) -> CGFloat {
            isCompact ? 16 : 20
        }

        static func vocabularyGridColumns(isCompact: Bool) -> Int {
            isCompact ? 2 : 3
        }

        static func petShopColumns(isCompact: Bool) -> Int {
            isCompact ? 3 : 4
        }
    }

    enum Fonts {
        static func titleSize(isCompact: Bool) -> CGFloat {
            isCompact ? 20 : 24
        }

        static func bodySize(isCompact: Bool) -> CGFloat {
            isCompact ? 15 : 17
        }

        static func captionSize(isCompact: Bool) -> CGFloat {
            isCompact ? 11 : 12
        }
    }
}
```

### 6.3 使用示例

```swift
// 网格列数
LazyVGrid(columns: Array(repeating: GridItem(.flexible()),
         count: AdaptiveLayout.Dimensions.vocabularyGridColumns(isCompact: isCompact)))

// 宠物尺寸
let petSize = AdaptiveLayout.Dimensions.floatingPetSize(isCompact: isCompact)

// 内边距
.padding(.horizontal, AdaptiveLayout.Dimensions.horizontalPadding(isCompact: isCompact))
```

## 7. 资源管理

### 7.1 Assets.xcassets 规范

**图片命名规则**:
- 小写字母 + 下划线：`pet_yinzhan`, `icon_coin`
- 宠物直接使用 ID：`yinzhan`, `kubao`

**加载方式**:
```swift
// ✅ 正确：从 Asset Catalog 加载
Image("yinzhan")
Image("coin")

// ❌ 避免：Bundle 路径加载
if let path = Bundle.main.path(forResource: "yinzhan", ofType: "png") { ... }
```

### 7.2 图片优化

| 资源 | 原始大小 | 优化后 | 压缩比 |
|------|---------|--------|-------|
| coin.png | 553KB | 9.8KB | 98% |
| 宠物图片 (10个) | 3.0MB | 0.75MB | 75% |
| AppIcon.png | 347KB | 722KB | PNG 1024x1024 |

### 7.3 课程主题图标

每个课程单元配有独特的主题图标：

```swift
var topicIcon: String {
    switch id {
    case 1: return "book.fill"           // Our New School - 学校用品
    case 2: return "person.fill"         // All About Us - 身体部位
    case 3: return "leaf.fill"           // Fun on the Farm - 农场动物
    case 4: return "fork.knife"          // Food With Friends - 食物
    case 5: return "gift.fill"           // Happy Birthday! - 生日派对
    case 6: return "car.fill"            // A Day Out - 交通工具
    case 7: return "gamecontroller.fill" // Let's Play! - 运动、游戏
    case 8: return "house.fill"          // At Home - 家居用品
    case 9: return "star.fill"           // Happy Holidays! - 节日
    default: return "book.fill"
    }
}
```

## 8. UI 组件设计

### 8.1 ViewModifiers 和组件复用

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

### 8.2 浮动宠物拖动实现

```swift
var body: some View {
    GeometryReader { geometry in
        // 计算边界
        let minX = petSize/2 + hPadding
        let maxX = screenW - petSize/2 - hPadding

        // 浮动宠物
        floatingPetImage
            .position(x: clampedX, y: clampedY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        // 保存位置
                        baseOffset = CGSize(width: newBaseX, height: newBaseY)
                    }
            )
    }
}
```

### 8.3 固定 Header 实现

Header 固定在顶部，内容区域可滚动：

```swift
ZStack {
    // Background
    Color(hex: "FEF7ED")
        .ignoresSafeArea()

    // Scrollable content
    ScrollView {
        VStack(spacing: 0) {
            // Spacer for fixed header
            Color.clear
                .frame(height: headerHeight)

            // Content...
        }
    }

    // Fixed header (on top of scrollable content)
    VStack(spacing: 0) {
        fixedHeaderSection
            .frame(height: headerHeight)
        Spacer()
    }
}

/// Header height calculation
private var headerHeight: CGFloat {
    let navBarHeight: CGFloat = isCompact ? 56 : 64
    return safeAreaTop + navBarHeight
}
```

**统一配置**（适用于 CourseListView、CloudShopView、SettingsView）：
| 参数 | iPhone (compact) | iPad (regular) |
|------|-----------------|----------------|
| navBarHeight | 56pt | 64pt |
| padding.top | safeAreaTop + 12 | safeAreaTop + 16 |
| padding.bottom | 14pt | 20pt |

## 9. 网络层设计

### 9.1 API 请求封装

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

### 9.2 错误处理策略

```swift
// 使用降级响应
do {
    let response = try await AIChatService.shared.sendMessage(...)
} catch {
    // 返回友好的默认响应
    return fallbackResponses.randomElement()!
}
```

## 10. 安全与隐私

### 10.1 敏感信息保护

**不提交到 Git 的文件**:
- `Config/APIConfig.swift` - API 密钥
- `Config/PromptConfig.swift` - Prompt 内容、学生信息
- `EnglishBuddyApp/CLAUDE.md` - 开发规范

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

### 10.2 数据传输安全

- 使用 HTTPS/WSS 进行 API 通信
- API Key 存储在本地，不硬编码
- 用户隐私数据（录音）仅本地存储

## 11. 性能优化

### 11.1 异步加载

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

// WebSocket 预连接
func prepareRecording() {
    Task {
        await AliyunASRService.shared.prepare()
    }
}
```

### 11.2 图片/音频缓存

```swift
struct ChatMessage {
    var audioData: Data?  // TTS 音频缓存
    var userVoiceData: Data?  // 用户录音缓存
}
```

### 11.3 LazyVStack 优化长列表

```swift
LazyVStack(spacing: 12) {
    ForEach(viewModel.lessons) { lesson in
        LessonRow(lesson: lesson)
    }
}
```

## 12. 历史对话记录

### 12.1 存储架构

**文件**: `Services/ChatHistoryStore.swift`

```swift
class ChatHistoryStore {
    static let shared = ChatHistoryStore()
    private let maxMessagesPerUnit = 200
    private let historyKey = "chatHistory"

    // 存储结构：[unitId: [PersistableMessage]]
    private var history: [Int: [PersistableMessage]] = [:]

    func loadHistory(for unitId: Int) -> [ChatMessage]
    func saveHistory(for unitId: Int, messages: [ChatMessage])
}
```

### 12.2 数据模型

```swift
// 可持久化的消息结构（不包含音频数据）
struct PersistableMessage: Codable {
    let id: UUID
    let text: String
    let speaker: Speaker
    let timestamp: Date
    let isError: Bool
}
```

**设计决策**:
- 音频数据不保存（节省存储空间）
- 按 unit 分隔存储（不同课程独立历史）
- 最多 200 条消息（防止存储过大）

### 12.3 时间标签实现

```swift
private func formatTimeLabel(_ date: Date) -> String {
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
        return DateFormatter.dateFormat(fromTemplate: "HH:mm")!.string(from: date)
    } else if calendar.isDateInYesterday(date) {
        return "昨天 " + DateFormatter.dateFormat(fromTemplate: "HH:mm")!.string(from: date)
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
        // 本周：星期x HH:mm
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    } else {
        // 其他：x月x日 HH:mm
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
```

### 12.4 会话隔离

**问题**: 历史消息不应发送给 AI，每次进入对话页都是新会话。

**解决方案**: 使用 `sessionStartTime` 区分当前会话和历史消息

```swift
// ChatViewModel.finishSession()
func finishSession() {
    // ... 统计学习时长 ...

    // 保存对话历史
    if let lesson = currentLesson {
        ChatHistoryStore.shared.saveHistory(for: lesson.id, messages: messages)
    }
}

// ChatViewModel.generateAIResponse()
private func generateAIResponse(to text: String) async {
    // 只发送当前会话的消息作为历史（不包含历史会话消息）
    let currentSessionMessages = messages.filter { message in
        guard let sessionStart = sessionStartTime else { return true }
        return message.timestamp >= sessionStart
    }
    let historyMessages = currentSessionMessages.dropLast()
    // ...
}
```

## 13. 开发规范

### 12.1 代码组织

```
EnglishBuddyApp/
├── Models/          # 数据模型
├── Views/           # SwiftUI 视图
├── ViewModels/      # 业务逻辑
├── Services/        # 网络服务、TTS、ASR
├── Utils/           # 工具类（AdaptiveLayout、Color扩展）
├── Extensions/      # Swift 扩展
├── Config/          # 配置文件 (gitignored)
└── Assets.xcassets/ # 图片资源
```

### 12.2 Git 工作流

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

3. **合并到 main**:
   ```bash
   git checkout main
   git merge feature/xxx
   git push origin main
   ```

### 12.3 命名规范

- **文件**: 大驼峰命名 `CourseListView.swift`
- **变量**: 小驼峰命名 `currentLesson`
- **常量**: 大写下划线 `CLOUD_COIN_DAILY_REWARD`
- **ViewModel**: 后缀 `ViewModel` `CourseViewModel`

## 13. 附录

### 13.1 第三方依赖

- **Speech Framework**: 语音权限（系统框架）
- **AVFoundation**: 音频播放（系统框架）
- **Observation**: 状态管理（Swift 6 原生）

### 13.2 外部服务

| 服务 | 用途 | 配置项 |
|------|------|--------|
| 阿里云 DashScope | AI 对话 | API Key, Model |
| 阿里云 TTS (流式) | 实时语音合成 | API Key, WebSocket, qwen3-tts-instruct-flash-realtime |
| 阿里云 TTS (非流式) | 语音合成降级 | API Key, cosyvoice-v2 |
| 阿里云 ASR | 实时语音识别 | API Key, WebSocket |

### 13.3 设备适配

| 设备 | horizontalSizeClass | 布局策略 |
|------|---------------------|----------|
| iPhone 竖屏 | .compact | 紧凑布局 |
| iPhone 横屏 | .regular | 宽屏布局 |
| iPad | .regular | 宽屏布局 |

### 13.4 更新记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-27 | 2.4 | 新增 App Icon、课程主题图标、固定 Header 实现方案 |
| 2026-03-27 | 2.3 | 新增历史对话记录技术方案（ChatHistoryStore、时间标签、会话隔离） |
| 2026-03-26 | 2.2 | 音频会话统一、竞态条件处理、录音优先级机制、超时回退机制 |
| 2026-03-25 | 2.1 | 新增流式 TTS 技术方案（WebSocket 实时语音合成） |
| 2026-03-25 | 2.0 | 更新云朵币系统、阿里云 ASR、响应式布局方案 |
| 2026-03-18 | 1.0 | 添加多轮对话技术方案 |
| 2026-03-08 | 0.5 | 初始版本 |