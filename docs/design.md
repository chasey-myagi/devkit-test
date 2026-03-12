# DevKit - 自动化开发工作台

## 概述

DevKit 是一个原生 macOS App（SwiftUI），用于监控 GitHub issue、管理开发流程、未来集成 Claude Code 实现全自动 SOP 执行。

**核心理念**：把 GitHub issue 从"被动查看"变成"主动驱动开发"，用户只需在看板上把 issue 状态改为 In Progress，其余全部自动化。

## 目标用户

个人开发者（当前用户），日常处理 matrixflow 仓库的 bug 修复和功能开发。

## 技术选型

| 维度 | 选择 | 理由 |
|------|------|------|
| 平台 | macOS 原生 | 进程管理、系统通知、终端调用最自然 |
| UI 框架 | SwiftUI | Apple 原生，声明式 |
| 数据持久化（本地） | SwiftData | Apple 原生 ORM，与 SwiftUI 深度集成 |
| 数据同步 | CloudKit | 零运维，多 Mac 同步，未来可扩展 iPhone |
| GitHub API | 全部通过 `gh` CLI | 鉴权由 `gh auth` 管理，零 token 维护 |
| 进程管理 | Foundation.Process | 调用 `gh` CLI、`git`、`make`、未来 `claude` CLI |
| 通知 | UserNotifications | macOS 原生通知 |

### GitHub API 鉴权策略

**所有 GitHub 交互统一通过 `gh` CLI 封装**，包括 REST 和 GraphQL 调用：
- `gh api /repos/{owner}/{repo}/issues` — REST 查询
- `gh api graphql -f query='...'` — GraphQL mutation（改 Projects.Status）
- 鉴权由 `gh auth` 管理，App 不处理 token

优点：简单可靠，用户只需确保 `gh auth login` 过即可。
缺点：每次调用 fork 子进程，性能略差。对于 30 分钟轮询频率完全可接受。

## 架构

```
DevKit.app
├── Presentation Layer (SwiftUI Views)
│   ├── WorkspaceView          # Workspace 管理（添加/切换）
│   ├── IssueBoardView         # Issue 看板（To Do / In Progress / Done）
│   ├── IssueDetailView        # 单个 issue 详情 + 附件 + 评论
│   ├── PRBoardView            # PR 看板（Draft / In Review / Need Fix / Ready）
│   ├── PRDetailView           # PR 详情（review + CI + 合并）
│   ├── ApprovalView           # 审批面板（未来 Agent 集成）
│   └── SettingsView           # 全局设置
│
├── Domain Layer (Business Logic)
│   ├── WorkspaceManager       # Workspace 配置（路径 ↔ repo 映射）
│   ├── GitHubMonitor          # 每 30min 轮询，检测 status 变化
│   ├── AgentOrchestrator      # 调度 Claude Code 进程（未来）
│   ├── SOPPipeline            # 8 阶段状态机（未来）
│   └── ApprovalGate           # 审批节点暂停/恢复控制（未来）
│
├── Infrastructure Layer
│   ├── GitHubCLIClient        # gh CLI 封装（REST + GraphQL）
│   ├── ClaudeCodeRunner       # Process API 封装（未来）
│   ├── WorktreeManager        # git worktree 创建/清理
│   ├── CloudKitSync           # 状态同步
│   └── NotificationService    # macOS 通知
│
└── Data Layer
    ├── CloudKit (CKRecord)    # 远端：workspace 配置、审批记录
    └── SwiftData (Local)      # 本地：issue/PR 缓存、日志、workspace 本地路径
```

## 数据模型

### Workspace

```swift
// SwiftData（本地）
@Model class Workspace {
    var name: String                    // e.g. "moi"
    var repoFullName: String            // e.g. "matrixorigin/matrixflow"
    var localPath: String               // e.g. "/Users/chasey/MOI/moi/matrixflow"（per-device，不同步）
    var pollingInterval: TimeInterval   // 默认 1800（30min）
    var maxConcurrency: Int             // 默认 2
}

// CloudKit（同步）— 只同步 name + repoFullName，不同步 localPath
// 每台 Mac 在本地 SwiftData 中维护自己的 localPath
```

### Issue

```swift
// SwiftData（纯本地缓存，不同步到 CloudKit）
@Model class Issue {
    var number: Int
    var title: String
    var labels: [String]                // ["kind/bug", "kind/bug-moi", "customer/中芯国际"]
    var severity: String?               // 从 labels 提取，e.g. "s0"
    var priority: String?               // 从 labels 提取，e.g. "p0"
    var customer: String?               // 从 labels 提取，e.g. "中芯国际"
    var projectStatus: String           // "To Do" / "In Progress" / "Done"
    var assignees: [String]
    var milestone: String?
    var attachmentURLs: [String]        // 从 issue body 提取的附件链接
    var updatedAt: Date
    var workspaceName: String           // 关联的 workspace
}
```

### PullRequest

```swift
// SwiftData（纯本地缓存，不同步到 CloudKit）
@Model class PullRequest {
    var number: Int
    var title: String
    var isDraft: Bool
    var additions: Int
    var deletions: Int
    var reviewState: PRReviewState      // .pending / .approved / .changesRequested
    var checksStatus: PRChecksStatus    // .passing / .failing / .pending
    var linkedIssueNumbers: [Int]       // 从 body 提取的关联 issue
    var updatedAt: Date
    var workspaceName: String
}
```

## 数据流

```
GitHub (Projects.Status 变化)
    │
    ▼
GitHubMonitor (每 30min 轮询 + 支持手动刷新 Cmd+R)
    │
    ▼
本地 SwiftData 缓存（每台 Mac 独立轮询，不通过 CloudKit 同步）
    │
    ├── Issue 看板渲染
    ├── PR 看板渲染
    └── 状态变化 → 触发：
        ├── 附件自动下载
        ├── Worktree 自动创建
        └── Agent SOP 启动（未来）
```

## 页面设计

### 1. Sidebar（常驻侧边栏）

- Workspace 切换器（下拉选择）
- 导航项：Issues / PRs / Settings
- Agent 运行状态指示器（未来）

### 2. Issue 看板页 (IssueBoardView)

三列看板：To Do / In Progress / Done

每张卡片展示：
- Issue 编号 + 标题
- 标签 badges（severity、customer、kind）
- 关联 PR 状态（如有）
- 距上次更新时间

操作：
- 拖拽改状态（或右键菜单）
- 双击进入详情
- 手动刷新（Cmd+R）
- 状态改为 In Progress 时自动：下载附件 + 创建 worktree

**拖拽改状态的乐观更新策略**：
1. 拖拽后 UI 立即更新（乐观更新）
2. 异步调 `gh api graphql` 修改远程状态
3. 成功 → 无感知；失败 → 弹通知 + UI 回滚到原状态
4. 下次轮询时以远程状态为准覆盖本地缓存

### 3. Issue 详情页 (IssueDetailView)

- 基本信息：标题、标签、severity、customer、milestone
- 附件列表 + 下载状态
- 评论流
- 关联 PR 状态
- Worktree 路径（可点击在 Finder/终端打开）
- Agent 8 阶段进度条（未来）

### 4. PR 看板页 (PRBoardView)

四列看板：Draft / In Review / Need Fix / Ready

**PR 状态映射规则**：

| 看板列 | 映射条件 | 优先级 |
|--------|---------|-------|
| Draft | `pr.draft == true` | 最高，draft 始终在此列 |
| Need Fix | 任一 review 状态为 `CHANGES_REQUESTED` | 高于 In Review |
| Ready | 所有 required review 为 `APPROVED` 且所有 checks 为 `SUCCESS`，且非 draft | 高于 In Review |
| In Review | 其他所有非 draft PR（默认列） | 兜底 |

每张卡片展示：
- PR 编号 + 标题
- 关联 issue 号
- diff 统计（+lines / -lines）
- CI 状态
- Review 状态（approve/change request 数量）
- 距上次更新时间

### 5. PR 详情页 (PRDetailView)

- Review comments 列表
- CI check runs 状态
- 合并操作（squash / rebase 可选）
  - 合并前自动检查 `mergeable` 状态和 required checks
  - 不满足条件时禁用合并按钮并显示原因
- 一键跳转 GitHub 网页查看 diff

注：原生 diff viewer 实现成本高，Phase 2 先用"跳转 GitHub"查看 diff，后续考虑 WKWebView 方案。

### 6. 审批页 (ApprovalView)（未来）

- Root Cause 审批：展示 root_cause.md 内容，通过/打回
- Fix Plan 审批：展示 fix_plan.md + BVT yaml，通过/打回

### 7. Settings 页 (SettingsView)

- Workspace 管理（增/删/路径配置）
- GitHub 账号状态（`gh auth status`）
- Agent 配置：并发上限（默认 2）、轮询间隔（默认 30min，可调 5min-60min）
- CloudKit 同步状态
- 关于 DevKit

## GitHub 集成

### Issue 监控

- 调用：`gh issue list --repo {repo} --assignee @me --state open --json number,title,labels,assignees,milestone,updatedAt`
- 获取 Projects.Status：`gh api graphql`（查询 `projectItems` 字段）
- 轮询频率：默认每 30 分钟，可配置（5min-60min）
- 支持手动刷新（Cmd+R）
- 筛选条件：assigned 给当前用户的 open issues

### Issue 状态管理

- 在 App 内改状态：`gh api graphql -f query='mutation { updateProjectV2ItemFieldValue(...) }'`
- None → 默认视为 To Do
- To Do → In Progress：触发自动准备（附件下载 + worktree 创建）
- In Progress → Done：issue 关闭或 PR merged 后自动

### PR 监控

- 调用：`gh pr list --repo {repo} --author @me --state open --json number,title,isDraft,additions,deletions,reviews,statusCheckRollup,updatedAt`
- 与 issue 关联：从 PR body 提取 `#issue_number` 或 `closes #xxx`

## 自动化行为（无需 Agent）

| 触发条件 | 自动执行 |
|---------|---------|
| Issue status → In Progress | 下载 issue 附件到 workspace、创建 git worktree |
| PR merged 且关联 issue | Issue status → Done |
| PR CI 失败 | 发 macOS 通知 |
| 新 issue 被 assign | 发 macOS 通知 |
| Review 有新 comment | 发 macOS 通知 |

## 错误处理

| 场景 | 策略 |
|------|------|
| 网络错误（GitHub API） | 静默跳过本次轮询，下次重试。连续 3 次失败弹通知 |
| `gh` CLI 未安装或未登录 | Settings 页提示，阻止轮询 |
| GitHub API rate limit (5000/hr) | 个人使用不太可能触发。若收到 403，暂停轮询 15 分钟 |
| 状态修改失败（GraphQL mutation） | 弹通知 + UI 回滚 |
| 附件下载失败 | 标记为失败状态，可在 issue 详情页手动重试 |
| Worktree 创建失败 | 弹通知，不阻塞其他流程 |

## 多设备同步（CloudKit）

### 同步范围

| 数据 | 存储位置 | 说明 |
|------|---------|------|
| Workspace 名称 + repo URL | CloudKit | 跨设备共享 |
| Workspace 本地路径 | SwiftData（仅本地） | 不同 Mac 路径不同，不同步 |
| Issue/PR 缓存 | SwiftData（仅本地） | 每台 Mac 独立轮询 GitHub，数据量小无需同步 |
| 审批记录 | CloudKit | 未来 Agent 审批历史 |
| Agent 日志 | SwiftData（仅本地） | 太大，不同步 |

### 同步策略

- CloudKit 只同步轻量配置数据，不同步 issue/PR 缓存
- 每台 Mac 独立轮询 GitHub，保证数据最新
- 未来 Agent 执行：只在用户指定的"主力 Mac"上运行，不做分布式锁，其他 Mac 只读看板 + 审批

## 与现有工具链的集成

App 通过 `Foundation.Process` 调用现有命令，复用已有工具链，不重复实现：

| 功能 | 调用方式 |
|------|---------|
| GitHub 交互 | `gh` CLI |
| 附件下载 | `make sync-issues ISSUES="{id}"` 或直接 HTTP 下载 |
| Worktree 创建 | `make worktree-create BRANCH=fix/{id}` |
| Worktree 清理 | `git worktree remove` |
| 未来 Agent | `claude -p "..."` 或其他方式 |

## 未来扩展（Agent 集成）

暂不设计，预留接口：

- `AgentOrchestrator`：接收 issue，启动 Claude Code 进程
- `SOPPipeline`：8 阶段状态机，每阶段对应一次 Claude Code 调用
- `ApprovalGate`：暂停 pipeline，等待用户审批后恢复
- `ClaudeCodeRunner`：封装 `Process` API 调用 claude CLI

Claude Code 的具体调用方式（`-p` 模式 / SDK / 其他）待后续确定。

## 并发控制

- 可配置最大并发数（默认 2）
- Phase 1-3 中并发控制仅体现为 UI 排序（severity → priority → 创建时间）
- Phase 4（Agent）中实现持久化队列：SwiftData 存储队列状态，App 重启后恢复

## 开发分期

### Phase 1（MVP，无 Agent）

1. Workspace 管理（添加/切换/路径配置）
2. GitHub issue 轮询 + 看板（三列）
3. Issue 详情 + 附件下载
4. Issue 状态管理（App 内改 Projects.Status）
5. 手动刷新（Cmd+R）
6. Settings

### Phase 1.5（自动化）

7. Worktree 自动创建
8. macOS 通知（新 assign、CI 失败、新 review）

### Phase 2（PR 看板）

9. PR 轮询 + 看板（四列）
10. PR 详情（review comments、CI、合并）
11. Issue ↔ PR 关联

### Phase 3（同步）

12. CloudKit 多 Mac 同步（workspace 配置）
13. per-device 路径映射

### Phase 4（Agent 集成）

14. Claude Code 调用方式确定
15. SOP Pipeline 状态机（持久化队列）
16. 审批页
17. Agent 进度面板

### Phase 5（iPhone）

18. iOS companion app（独立 UI 设计，复用 Domain + Infrastructure Layer）
19. 功能：只读看板 + 审批
// Dark mode config
