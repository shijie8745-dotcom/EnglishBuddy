# EnglishBuddy 项目开发规范

## Git 工作流规则

### 分支开发策略

**所有代码修改必须遵循以下规则：**

1. **优先本地分支开发**
   - 任何新功能、bug修复或代码调整，先在本地创建分支
   - 禁止直接在 `main` 分支上修改代码

2. **分支创建命令**
   ```bash
   git checkout -b feature/xxx      # 新功能
   git checkout -b fix/xxx          # Bug修复
   git checkout -b refactor/xxx     # 代码重构
   ```

3. **本地验证后再推送**
   - 在本地分支完成开发和测试
   - 确认功能正常、代码无误后，再推送到 GitHub
   - 推送前检查：
     ```bash
     git status          # 检查修改状态
     git diff            # 检查具体变更
     git log --oneline   # 检查提交历史
     ```

4. **推送命令**
   ```bash
   git push origin feature/xxx
   ```

### 为什么这样做？

- **隔离性**：本地分支的修改不影响主分支代码和功能
- **安全性**：测试验证通过后再公开，避免推送半成品代码
- **灵活性**：本地可以随时切换分支、撤销修改、重写提交历史
- **协作规范**：GitHub 上只保留经过验证的稳定代码

### 工作流程示例

```bash
# 1. 从 main 分支创建新分支
git checkout main
git pull origin main
git checkout -b feature/new-feature

# 2. 在本地开发、测试、提交
git add .
git commit -m "Add new feature"

# 3. 反复修改直到满意（不打断主分支）
# ... 修改代码 ...
# ... 本地测试 ...
# ... 再次提交 ...

# 4. 确认没问题后推送到 GitHub
git push origin feature/new-feature

# 5. 创建 Pull Request 合并到 main
```

---

## 项目架构说明

### 目录结构

```
EnglishBuddyApp/
├── Config/                 # 配置文件（敏感信息，gitignored）
│   ├── APIConfig.swift           # API密钥（本地创建）
│   ├── APIConfig.swift.example   # API密钥示例
│   ├── PromptConfig.swift        # Prompt配置（本地创建）
│   └── PromptConfig.swift.example # Prompt示例
├── Models/                 # 数据模型
├── Views/                  # SwiftUI视图
├── ViewModels/             # 业务逻辑
├── Services/               # 网络服务、TTS等
├── Utils/                  # 工具类
└── Resources/              # 资源文件
```

### 敏感文件注意

以下文件包含敏感信息，**绝不能推送到 GitHub**：

- `Config/APIConfig.swift` — API密钥
- `Config/PromptConfig.swift` — Prompt内容、学生信息

如需修改这些文件，请：
1. 先复制 `.example` 文件创建本地版本
2. 填入真实值
3. 确保 `.gitignore` 正确配置
4. **仅推送 `.example` 文件到 GitHub**
