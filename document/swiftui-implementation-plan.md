# EnglishBuddy SwiftUI 实现计划

## 项目概述

- **技术栈**: SwiftUI (iOS 26+), Swift 6
- **架构模式**: MVVM + @Observable
- **数据存储**: UserDefaults + JSON
- **AI 服务**: 阿里云 DashScope (OpenAI 兼容 API)

---

## Phase 1 - 基础架构 (已完成)

### 1.1 项目初始化
- [x] 创建 SwiftUI 项目
- [x] 设置目录结构 (Models, Views, ViewModels, Services, Utils)
- [x] 配置 .gitignore (忽略 Config 中的敏感文件)

### 1.2 核心数据模型
| 模型 | 文件 | 关键属性 | 状态 |
|------|------|----------|------|
| User | `Models/User.swift` | name, apiKey, currentPracticeLessonId, carrots | ✅ |
| Pet | `Models/Pet.swift` | name, level, experience, positionX/Y | ✅ |
| Lesson | `Models/Lesson.swift` | id, title, vocabulary, sentencePatterns | ✅ |
| ChatMessage | `Models/ChatMessage.swift` | text, speaker, audioData, timestamp | ✅ |
| CheckInRecord | `Models/CheckInRecord.swift` | date, earnedCarrots, isBonus | ✅ |
| LessonProgress | `Models/Lesson.swift` | isCompleted, studyCount, totalStudyTime | ✅ |

### 1.3 数据持久化服务
- [x] DataStore 单例类
- [x] UserDefaults 封装 (save/load)
- [x] 支持 User, Pet, Progress, CheckInRecords

---

## Phase 2 - 课程系统 (已完成)

### 2.1 课程列表视图
**文件**: `Views/CourseListView.swift`

**已实现组件**:
- [x] 橙色渐变 Header
- [x] 练一练快捷卡片 (青色渐变)
- [x] 签到按钮 (右侧固定宽度)
- [x] 学习统计数据行 (3 列卡片)
- [x] 课程列表 (LazyVStack)
- [x] 课程状态图标 (完成/进行中/锁定)
- [x] 导航到课程详情
- [x] AI 测试页面入口按钮
- [x] 设置页面入口按钮

**代码结构**:
```swift
struct CourseListView: View {
    @State private var viewModel = CourseViewModel()
    @State private var showingCheckIn = false
    @State private var showingFeedPet = false
}
```

### 2.2 课程详情视图
**文件**: `Views/CourseDetailView.swift`

**已实现**:
- [x] 课程信息展示
- [x] 词汇表 (Vocabulary cards)
- [x] 句型学习 (Sentence patterns)
- [x] 开始学习按钮 (导航到 ChatView)

### 2.3 练一练功能
**实现方式**:
- 使用 `User.currentPracticeLessonId` 存储选择
- `CourseViewModel.practiceLesson` 计算属性返回当前课程
- 首页卡片直接导航到 ChatView
- 支持在 SettingsView 中切换课程

---

## Phase 3 - AI 对话系统 (已完成)

### 3.1 AI 对话服务
**文件**: `Services/AIChatService.swift`

**已实现功能**:
- [x] OpenAI 兼容格式请求
- [x] 多轮对话支持 (historyMessages 参数)
- [x] 课程相关 Prompt 加载 (PromptConfig)
- [x] 错误处理和降级响应
- [x] 流式响应支持 (streamMessage 方法)

**核心方法**:
```swift
func sendMessage(
    _ message: String,
    lessonId: Int,
    historyMessages: [ChatMessage] = []
) async throws -> String
```

### 3.2 主对话页面 (语音输入)
**文件**: `Views/ChatView.swift`

**已实现**:
- [x] 语音输入 (按住说话)
- [x] 实时语音识别显示
- [x] AI 消息气泡 (橙色渐变)
- [x] 用户消息气泡 (蓝色)
- [x] AI 头像展示 (Amy)
- [x] TTS 语音播放
- [x] 点击重播功能
- [x] 多轮对话上下文记忆
- [x] 页面导航和返回

**代码结构**:
```swift
struct ChatView: View {
    let lesson: Lesson
    var isFromPractice: Bool = false
    @State private var viewModel = ChatViewModel()
}
```

### 3.3 AI 测试页面 (文本输入)
**文件**: `Views/AIChatTestView.swift`

**已实现**:
- [x] 文本输入框
- [x] 发送按钮
- [x] 页面自动触发 AI 问候 (onAppear)
- [x] 系统 TTS 播放 (节省 API 费用)
- [x] 消息播放状态指示
- [x] 多轮对话支持
- [x] 课程相关 Prompt

**ViewModel 结构**:
```swift
class AIChatTestViewModel: NSObject {
    var messages: [ChatMessage] = []
    var lesson: Lesson?
    private let synthesizer = AVSpeechSynthesizer()
}
```

### 3.4 对话消息组件
**文件**: `Views/ChatView.swift` (嵌套组件)

- [x] ChatBubble - 消息气泡组件
- [x] TypingIndicator - 输入中指示器
- [x] PlayingIndicator - 播放状态动画
- [x] MicrophoneButton - 录音按钮

---

## Phase 4 - 游戏化系统 (已完成)

### 4.1 学习宠物系统
**文件**: `Views/PetView.swift`, `Views/FeedPetView.swift`

**PetView (主宠物展示)**:
- [x] 圆形头像 (80x80pt)
- [x] 3px 橙色边框
- [x] 信息标签 (名称 | 等级 | 胡萝卜数量)
- [x] DragGesture 拖动支持
- [x] 位置保存到 UserDefaults
- [x] 点击打开喂食弹窗

**FeedPetView (喂食弹窗)**:
- [x] 宠物大图展示
- [x] 等级和名称显示
- [x] 经验进度条
- [x] 胡萝卜数量显示
- [x] 喂食按钮 (消耗 1 胡萝卜，+50 经验)
- [x] 升级逻辑 (每 100 经验升 1 级)

### 4.2 签到系统
**文件**: `Views/CheckInView.swift`

**已实现**:
- [x] 月度日历视图 (7 列网格)
- [x] 已签到标记 (绿色渐变)
- [x] 今日未签到标记 (橙色边框)
- [x] 签到按钮 (大按钮，已签到后禁用)
- [x] 统计数据 (累计签到、连续天数、胡萝卜)
- [x] 奖励规则说明列表
- [x] 连续签到奖励计算

**ViewModel**: `CheckInViewModel`
- `checkIn()` 方法：计算奖励并更新用户数据
- `calculateConsecutiveDays()`：计算连续签到天数

### 4.3 奖励机制
**文件**: `Models/CheckInRecord.swift`

```swift
enum CheckInReward {
    static let daily = 5           // 每日签到
    static let consecutive3Days = 5  // 连续 3 天额外奖励
    static let consecutive7Days = 10 // 连续 7 天额外奖励
    static let studyPerMinute = 1    // 学习每分钟奖励
}
```

---

## Phase 5 - 用户系统 (已完成)

### 5.1 设置页面
**文件**: `Views/SettingsView.swift`

**已实现模块**:
- [x] 用户信息设置 (昵称、头像)
- [x] API Key 设置
- [x] AI 模型选择
- [x] 语音语速调节
- [x] 练一练课程选择 (网格布局)
- [x] 学习统计展示
- [x] 宠物统计展示

### 5.2 视图模型
**文件**: `ViewModels/CourseViewModel.swift`

**核心方法**:
```swift
func setPracticeLesson(_ lesson: Lesson)
func checkIn() -> Int
func feedPet() -> Bool
func status(for lesson: Lesson) -> LessonStatus
func completeLesson(_ lesson: Lesson, studyTime: Int)
```

---

## 模块依赖关系

```
CourseListView
    ├── NavigationLink → ChatView (课程学习)
    ├── NavigationLink → AIChatTestView (AI测试)
    ├── NavigationLink → CheckInView (签到)
    ├── NavigationLink → SettingsView (设置)
    └── PetView (浮动宠物)
        └── Sheet → FeedPetView (喂食)

ChatView / AIChatTestView
    └── ChatViewModel / AIChatTestViewModel
        └── AIChatService
            └── PromptConfig
```

---

## 关键技术决策

### 1. 状态管理
- 使用 `@Observable` 宏替代 ObservableObject
- ViewModel 作为 @State 存储在 View 中
- 数据变更自动触发 UI 更新

### 2. 导航架构
- NavigationStack 作为主导航容器
- NavigationLink 进行页面跳转
- 使用 dismiss() 返回上级页面

### 3. 数据流
```
User Action → View → ViewModel → Service → API/Storage
                                     ↓
                              Response → ViewModel → View Update
```

### 4. 错误处理策略
- 网络错误：显示友好提示，提供降级响应
- API 错误：记录日志，使用本地缓存或默认响应
- 权限错误：引导用户开启权限

---

## 测试策略

### 单元测试点
- [ ] CourseViewModel 业务逻辑
- [ ] CheckInReward 计算规则
- [ ] Pet 升级逻辑

### UI 测试点
- [ ] 课程列表导航
- [ ] 对话消息滚动
- [ ] 宠物拖动和喂食

### 集成测试点
- [ ] AI 服务请求/响应
- [ ] 语音识别流程
- [ ] 数据持久化

---

## 更新记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-18 | 1.0 | 完成所有 Phase，添加多轮对话支持 |
| 2026-03-16 | 0.9 | 完成 AI 测试页面 |
| 2026-03-12 | 0.8 | 完成设置页面重构 |
| 2026-03-09 | 0.7 | 完成宠物和签到系统 |
| 2026-03-08 | 0.5 | 完成基础课程系统 |
