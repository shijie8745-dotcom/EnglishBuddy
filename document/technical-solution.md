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

**阿里云 qwen3-TTS-Instruct-Flash**:
```swift
func speak(_ text: String, for messageId: UUID) async -> Data? {
    let requestBody: [String: Any] = [
        "model": "cosyvoice-v1",
        "input": text,
        "voice": "longxiaochun",
        "format": "wav"
    ]
    // 请求并返回音频数据
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

## 12. 开发规范

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
| 阿里云 TTS | 语音合成 | API Key |
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
| 2026-03-25 | 2.0 | 更新云朵币系统、阿里云 ASR、响应式布局方案 |
| 2026-03-18 | 1.0 | 添加多轮对话技术方案 |
| 2026-03-08 | 0.5 | 初始版本 |