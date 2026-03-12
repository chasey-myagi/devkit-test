# CloudKit 同步 + AgentCore 设计文档

## 概览

本文档包含两个功能的设计：
1. **CloudKit 同步** — 跨设备同步 Workspace 配置（立即实现）
2. **AgentCore 智能助手** — 应用内置 AI 管理 Agent（仅设计，暂不实现）

---

## 一、CloudKit 同步

### 1.1 目标

让用户在多台 Mac 上共享 Workspace 配置（名称、repo、本地路径、轮询间隔等），无需手动重复配置。

### 1.2 同步范围

| Model | 同步方式 | 理由 |
|-------|---------|------|
| `Workspace` | CloudKit Private DB | 用户配置，需要跨设备共享 |
| `CachedIssue` | 纯本地 | GitHub 缓存数据，各设备独立从 GitHub 拉取更可靠 |
| `CachedPR` | 纯本地 | 同上 |

### 1.3 架构：双 ModelContainer

```
┌─────────────────────────────────────────────────┐
│                  DevKitApp                       │
│                                                  │
│  cloudContainer (CloudKit Private DB)            │
│  ├─ Workspace                                    │
│  └─ 自动同步 ↔ iCloud.com.chasey.DevKit          │
│                                                  │
│  localContainer (纯本地 SQLite)                   │
│  ├─ CachedIssue                                  │
│  └─ CachedPR                                     │
└─────────────────────────────────────────────────┘
```

**核心原则：** Workspace 走 CloudKit 自动同步，Issue/PR 缓存纯本地存储，两套数据互不干扰。

### 1.4 ContainerContext 注入

SwiftUI 的 `.modelContainer()` 只能注入一个 container，因此需要一个统一管理类：

```swift
@Observable
final class ContainerContext {
    let cloudContainer: ModelContainer   // Workspace (CloudKit)
    let localContainer: ModelContainer   // CachedIssue, CachedPR (本地)

    var cloudContext: ModelContext { cloudContainer.mainContext }
    var localContext: ModelContext { localContainer.mainContext }
}
```

**注入策略：**

- `.modelContainer(cloudContainer)` 挂在 `WindowGroup` — `@Query` 查 `Workspace` 自动走 CloudKit
- `IssueBoardView` / `PRBoardView` 额外挂 `.modelContainer(localContainer)` — `@Query` 查 Issue/PR 走本地
- ViewModel / Service 构造时传入 `localContainer`

**影响范围：**

| 组件 | 改动 |
|------|------|
| `DevKitApp` | 创建两个 container，注入 `ContainerContext` |
| `ContentView` | 从 environment 取 `ContainerContext`，Board 视图挂 localContainer |
| `IssueBoardView` / `PRBoardView` | 无改动（`@Query` 自动从挂载的 container 查询） |
| `SettingsView` | 无改动（`@Query` Workspace 走 cloudContainer） |
| `GitHubMonitor` | 构造时传 `localContainer` |
| `IssueBoardViewModel` | 构造时传 `localContainer` |
| `PRBoardViewModel` | 构造时传 `localContainer` |
| `WorkspaceManager` | 构造时传 `cloudContainer` |

### 1.5 Workspace 模型 CloudKit 兼容性

CloudKit 自动同步要求：
- ✅ 所有属性有默认值 — 当前已满足
- ✅ 不使用 `#Unique` 约束 — 当前已满足
- ✅ 属性类型为 CloudKit 支持的类型（String, Int, Bool, Date 等）— 当前已满足

**无需修改 `Workspace` 模型。**

### 1.6 CloudKit 配置

**Entitlements 文件** — `DevKit/DevKit.entitlements`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.chasey.DevKit</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

**project.yml 添加：**

```yaml
settings:
  base:
    CODE_SIGN_ENTITLEMENTS: DevKit/DevKit.entitlements
```

**手动步骤：** 需要在 Apple Developer 后台注册 iCloud container `iCloud.com.chasey.DevKit`。

### 1.7 冲突处理

SwiftData + CloudKit 使用 **last-writer-wins** 策略：

| 场景 | 行为 | 可接受性 |
|------|------|---------|
| 两台设备同时改同一 Workspace 的轮询间隔 | 后写入覆盖 | ✅ 可接受 |
| 一台添加 Workspace，另一台删除 | 各自生效 | ✅ 可接受 |
| 两台同时创建同名 Workspace | 产生重复 | ⚠️ 需要去重 |

**去重策略：** 在 `WorkspaceManager` 添加 `deduplicateWorkspaces()` 方法，在 app 启动和收到 CloudKit 远程变更通知时调用。按名称去重，保留最先插入的记录。

### 1.8 测试策略

- 单元测试：`ContainerContext` 创建、双 container 隔离验证
- 单元测试：`WorkspaceManager.deduplicateWorkspaces()` 去重逻辑
- 单元测试：ViewModel 使用 localContainer 的正确性
- 集成测试：需要真实 iCloud 账号，手动验证

---

## 二、AgentCore 智能助手（仅设计，暂不实现）

### 2.1 目标

在 DevKit 应用内置一个 AI 管理助手，用户通过 `Cmd+K` 命令栏用自然语言与 Agent 交互，实现智能搜索、操作执行、配置管理。

### 2.2 架构

```
DevKit (Swift)                          AgentCore (TypeScript / Bun)
┌──────────────┐    HTTP localhost:7890   ┌──────────────────────┐
│  Cmd+K UI    │ ──── POST /chat ──────→ │  HTTP Server (Hono)   │
│  命令栏       │ ←─── SSE stream ─────── │  pi-ai + pi-agent-core│
└──────────────┘                         └──────────────────────┘
      │                                         │
      │ spawn/kill 子进程                         │ Tool Use
      │                                         ▼
      │                                  ┌──────────────────────┐
      │                                  │ Anthropic API         │
      │                                  │ (Haiku / Sonnet)      │
      │                                  └──────────────────────┘
```

**核心特征：**
- **独立进程** — AgentCore 是 Swift app 的子进程，故障隔离，挂了不影响主功能
- **无状态** — 崩溃后自动重启，无数据丢失
- **轻量** — 使用 Bun 运行时，打包为单二进制嵌入 app bundle

### 2.3 技术栈

| 组件 | 技术 |
|------|------|
| 运行时 | Bun |
| Agent 框架 | `@mariozechner/pi-ai` + `@mariozechner/pi-agent-core` |
| HTTP 服务 | Hono |
| LLM Provider | Anthropic（默认 Haiku，可切换 Sonnet） |

### 2.4 进程管理

- Swift app 启动时通过 `Process()` spawn AgentCore 进程
- 退出时 kill 子进程
- 崩溃检测 + 自动重启（最多 3 次，超过则通知用户）
- 端口选择：默认 7890，冲突时自动寻找可用端口

### 2.5 通信协议

**请求：** `POST http://localhost:7890/chat`

```json
{
  "message": "找出所有 s0 的 bug",
  "context": {
    "workspaceName": "my-project",
    "repoFullName": "org/repo"
  }
}
```

**响应：** SSE 流式返回

```
data: {"type": "text", "content": "找到 3 个 s0 级别的 bug："}
data: {"type": "text", "content": "\n1. #123 跨页表合并错误..."}
data: {"type": "action", "tool": "search_issues", "result": [...]}
data: {"type": "done"}
```

### 2.6 工具定义

| Tool | 描述 | 参数 |
|------|------|------|
| `search_issues` | 搜索 issue | query, labels, assignee, milestone, status |
| `search_prs` | 搜索 PR | query, reviewState, checksStatus, boardColumn |
| `update_issue_status` | 移动 issue 状态 | issueNumber, newStatus |
| `get_workspace_config` | 查看 workspace 配置 | — |
| `update_workspace_config` | 修改配置 | key, value |
| `refresh` | 手动触发刷新 | — |
| `get_stats` | 统计信息 | — |

### 2.7 数据访问

AgentCore 通过两种方式访问数据：

1. **HTTP 回调** — Swift app 暴露 `localhost:7891` 内部 API，AgentCore 调用来读写 SwiftData
2. **直接读取 SQLite**（只读查询）— 对于搜索操作，直接读取 SwiftData 的 SQLite 文件，避免回调开销

### 2.8 Cmd+K 命令栏 UI（Swift 侧）

- 全局快捷键 `Cmd+K` 打开浮动命令栏
- 输入框 + 流式响应展示区域
- 类似 Raycast/Spotlight 的交互，执行完自动关闭（或保持展示结果）
- Agent 不可用时（进程未启动/崩溃）显示提示

### 2.9 Settings 配置

在现有 Agent tab 中实现：
- API Key 输入（Anthropic API Key）
- 模型选择（Haiku / Sonnet）
- Agent 启用/禁用开关
- Agent 状态指示（运行中/已停止/错误）

---

## 实施优先级

1. ✅ **CloudKit 同步** — 立即实施
2. 📝 **AgentCore** — 设计完成，待后续实施
