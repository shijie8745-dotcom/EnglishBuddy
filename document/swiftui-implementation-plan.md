# EnglishBuddy SwiftUI 实现计划

## 项目概述

- **技术栈**: SwiftUI (iOS 26+), Swift 6
- **架构模式**: MVVM + @Observable
- **数据存储**: UserDefaults + JSON
- **AI 服务**: 阿里云 DashScope (OpenAI 兼容 API)
- **语音服务**: 阿里云 ASR + TTS

---

## Phase 1 - 基础架构 (已完成)

### 1.1 项目初始化
- [x] 创建 SwiftUI 项目
- [x] 设置目录结构 (Models, Views, ViewModels, Services, Utils)
- [x] 配置 .gitignore (忽略 Config 中的敏感文件)

### 1.2 核心数据模型
| 模型 | 文件 | 关键属性 | 状态 |
|------|------|----------|------|
| User | `Models/User.swift` | name, apiKey, currentPracticeLessonId, petCollection | ✅ |
| PetCollection | `Models/PetCollection.swift` | currentPetId, unlockedPets | ✅ |
| Lesson | `Models/Lesson.swift` | id, title, vocabulary, sentencePatterns | ✅ |
| ChatMessage | `Models/ChatMessage.swift` | text, speaker, audioData, timestamp | ✅ |
| CloudCoinSystem | `Models/CloudCoinSystem.swift` | coins, checkInRecords, todayChatCount, totalChatCount | ✅ |
| LessonProgress | `Models/Lesson.swift` | isCompleted, studyCount, totalStudyTime | ✅ |

### 1.3 数据持久化服务
- [x] DataStore 单例类
- [x] UserDefaults 封装 (save/load)
- [x] 支持 User, PetCollection, Progress, CloudCoinSystem

---

## Phase 2 - 课程系统 (已完成)

### 2.1 课程列表视图
**文件**: `Views/CourseListView.swift`

**已实现组件**:
- [x] 橙色渐变 Header
- [x] 用户头像展示
- [x] 练一练快捷卡片 (青色渐变)
- [x] 云朵商店入口按钮
- [x] 学习统计数据行 (累计打卡/学习时长/累计对话)
- [x] 课程列表 (LazyVStack)
- [x] 课程状态图标 (完成/进行中)
- [x] 导航到课程详情
- [x] 设置页面入口按钮
- [x] 浮动宠物展示

**响应式布局**:
```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
private var isCompact: Bool { horizontalSizeClass == .compact }
```

### 2.2 课程详情视图
**文件**: `Views/Unit1CourseDetailView.swift` ~ `Unit9CourseDetailView.swift`

**已实现**:
- [x] 课程信息展示
- [x] 词汇表 (Vocabulary cards - 2/3列自适应)
- [x] 句型学习 (Sentence patterns)
- [x] 开始学习按钮 (导航到 ChatView)
- [x] 自适应布局（iPhone/iPad）

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

### 3.2 TTS 服务
**文件**: `Services/TTSService.swift`

**已实现**:
- [x] 阿里云 TTS API 调用
- [x] 音频数据缓存
- [x] 播放状态管理
- [x] 语速控制

### 3.3 语音识别服务
**文件**: `Services/AliyunASRService.swift`

**已实现**:
- [x] WebSocket 实时语音识别
- [x] 阿里云 ASR 集成
- [x] 实时转写结果回调
- [x] 连接状态管理
- [x] 预连接优化

### 3.4 主对话页面 (语音输入)
**文件**: `Views/ChatView.swift`

**已实现**:
- [x] 语音输入 (按住说话)
- [x] 实时语音识别显示
- [x] AI 消息气泡 (橙色渐变)
- [x] 用户消息气泡 (蓝色)
- [x] AI 头像展示 (Amy - teacher.imageset)
- [x] TTS 语音播放
- [x] 点击重播功能
- [x] 多轮对话上下文记忆
- [x] 学习时长统计 (>30秒算1分钟)
- [x] 对话次数统计

**代码结构**:
```swift
struct ChatView: View {
    let lesson: Lesson
    var isFromPractice: Bool = false
    @State private var viewModel = ChatViewModel()
}
```

### 3.5 对话消息组件
**文件**: `Views/ChatView.swift` (嵌套组件)

- [x] ChatBubble - 消息气泡组件
- [x] TypingIndicator - 输入中指示器
- [x] PlayingIndicator - 播放状态动画
- [x] VoiceButton - 语音输入按钮
- [x] CancelButton - 取消按钮
- [x] VoiceBubble - 录音状态气泡

---

## Phase 4 - 游戏化系统 (已完成)

### 4.1 云朵币系统
**文件**: `Models/CloudCoinSystem.swift`

**核心功能**:
- [x] 云朵币赚取（学习时长、打卡）
- [x] 云朵币消费（购买宠物）
- [x] 打卡记录管理
- [x] 对话次数统计
- [x] 连续打卡天数计算

**奖励规则**:
```swift
enum CloudCoinReward {
    static let daily = 5           // 每日打卡
    static let consecutive3Days = 5  // 连续 3 天额外奖励
    static let consecutive7Days = 10 // 连续 7 天额外奖励
    static let studyPerMinute = 1    // 学习每分钟
    static let petPrice = 200        // 宠物价格
}
```

### 4.2 云朵商店
**文件**: `Views/CloudShopView.swift`

**已实现**:
- [x] 宠物网格展示 (iPhone 3列/iPad 4列)
- [x] 宠物预览弹窗
- [x] 购买功能
- [x] 切换已拥有宠物
- [x] 云朵币余额显示
- [x] 打卡进度条
- [x] 月度打卡日历
- [x] 获取规则说明

### 4.3 宠物系统
**文件**: `Models/PetCollection.swift`

**宠物列表**:
| ID | 名称 | 状态 |
|----|------|------|
| yinzhan | 音战 | ✅ 默认解锁 |
| kubao | 酷宝 | ✅ |
| dianmiao | 电喵 | ✅ |
| saibo | 赛博 | ✅ |
| fenmiao | 粉喵 | ✅ |
| kushao | 酷少 | ✅ |
| yinren | 银刃 | ✅ |
| luluo | 绿萝 | ✅ |
| feihong | 绯红 | ✅ |
| jiniang | 机娘 | ✅ |

**首页浮动宠物**:
- [x] 可拖动定位
- [x] 位置记忆
- [x] 自适应尺寸

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
- [x] 云朵币余额显示

---

## Phase 6 - 设备适配 (已完成)

### 6.1 响应式布局工具
**文件**: `Utils/AdaptiveLayout.swift`

**自适应尺寸**:
```swift
struct Dimensions {
    static func floatingPetSize(isCompact: Bool) -> CGFloat
    static func statIconSize(isCompact: Bool) -> CGFloat
    static func horizontalPadding(isCompact: Bool) -> CGFloat
    static func vocabularyGridColumns(isCompact: Bool) -> Int
    static func petShopColumns(isCompact: Bool) -> Int
}

struct Fonts {
    static func titleSize(isCompact: Bool) -> CGFloat
    static func bodySize(isCompact: Bool) -> CGFloat
    static func captionSize(isCompact: Bool) -> CGFloat
}
```

### 6.2 Size Class 适配

| 场景 | horizontalSizeClass | 布局效果 |
|------|---------------------|----------|
| iPhone 竖屏 | .compact | 紧凑布局 |
| iPhone 横屏 | .regular | 宽屏布局 |
| iPad | .regular | 宽屏布局 |

---

## 模块依赖关系

```
CourseListView
    ├── NavigationLink → ChatView (课程学习)
    ├── NavigationLink → CloudShopView (云朵商店)
    ├── NavigationLink → SettingsView (设置)
    └── Floating Pet (当前宠物)

ChatView
    └── ChatViewModel
        ├── AIChatService
        ├── AliyunASRService
        ├── TTSService
        └── PromptConfig

CloudShopView
    └── CloudShopViewModel
        └── DataStore (用户数据)
```

---

## 资源管理

### Assets.xcassets 结构
```
Assets.xcassets/
├── coin.imageset/        # 云朵币图标
├── teacher.imageset/     # AI 教师头像
├── yinzhan.imageset/     # 宠物：音战
├── kubao.imageset/       # 宠物：酷宝
├── dianmiao.imageset/    # 宠物：电喵
├── saibo.imageset/       # 宠物：赛博
├── fenmiao.imageset/     # 宠物：粉喵
├── kushao.imageset/      # 宠物：酷少
├── yinren.imageset/      # 宠物：银刃
├── luluo.imageset/       # 宠物：绿萝
├── feihong.imageset/     # 宠物：绯红
└── jiniang.imageset/     # 宠物：机娘
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

## 更新记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-03-25 | 2.0 | 更新云朵币系统、宠物商店、iPhone 适配、阿里云 ASR |
| 2026-03-18 | 1.0 | 完成所有 Phase，添加多轮对话支持 |
| 2026-03-16 | 0.9 | 完成 AI 测试页面 |
| 2026-03-12 | 0.8 | 完成设置页面重构 |
| 2026-03-09 | 0.7 | 完成宠物和签到系统 |
| 2026-03-08 | 0.5 | 完成基础课程系统 |