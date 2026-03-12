# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
cd DevKit
xcodegen generate                              # 生成 Xcode 项目（修改 project.yml 后必须重新执行）
xcodebuild build -scheme DevKit -configuration Debug   # 编译
xcodebuild test -scheme DevKit -configuration Debug    # 运行全部测试
xcodebuild test -scheme DevKit -only-testing DevKitTests/GitHubCLIClientTests  # 单个测试文件
```

- 构建系统：XcodeGen（`DevKit/project.yml`），macOS 15.0+，Swift 6.0
- 测试框架：Swift Testing（原生 `@Test` 宏），不使用 XCTest
- 无第三方依赖，全部使用 Apple 原生框架

## Architecture

MVVM + 分层架构，数据从 GitHub 到 UI 的单向流：

```
GitHub (gh CLI) → GitHubMonitor (定时轮询) → SwiftData 缓存 → @Query 驱动 View 更新
```

**关键层：**
- **Views** (`Views/`): SwiftUI 视图，NavigationSplitView 侧边栏 + 详情面板
- **ViewModels** (`ViewModels/`): `@Observable` 宏（非 ObservableObject），编排业务逻辑
- **Services** (`Services/`): `GitHubCLIClient`（gh CLI 封装）、`GitHubMonitor`（轮询）、`WorkspaceManager`、`WorktreeManager`、`NotificationService`
- **Models** (`Models/`): `@Model` SwiftData 持久化（`CachedIssue`、`CachedPR`、`Workspace`）

**核心模式：**
- 状态管理用 `@Observable` + `@Query` + `@State`，不用 `ObservableObject`/`@StateObject`
- 依赖注入通过协议（如 `ProcessRunning`），测试时注入 Mock
- 乐观更新：拖放改状态时 UI 立即响应，API 失败则回滚
- GitHub API 全部走 `gh` CLI（REST + GraphQL），不直接管理 token
- 并发用 async/await + TaskGroup，不用 DispatchQueue
- 刷新快捷键 Cmd+R 通过 NotificationCenter 广播

## Design System

**规范文档：** `docs/superpowers/specs/2026-03-12-design-system-spec.md`

Token-First 设计系统，所有视觉值通过 Token 定义，禁止硬编码样式。开发 UI 时必须参照此规范：

- **颜色**：通过 `DKColor.Surface.*` / `DKColor.Foreground.*` / `DKColor.Accent.*` 引用，在 Assets.xcassets 中定义浅色/深色两套
- **字体**：通过 `DKTypography` 或 `dkTextStyle()` ViewModifier 应用（含 tracking + lineSpacing）
- **间距**：`DKSpacing.*`（4pt 网格：xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48）
- **圆角**：`DKRadius.*`（sm=6, md=12, lg=20, xl=28, hero=32）
- **动画**：`DKMotion.Spring.*` / `DKMotion.Ease.*`，仅动画 transform 属性（opacity/scale/offset/rotation/shadow），不动画 frame/padding
- **按钮**：使用 `ButtonStyle` 实现按压效果，不用 `onLongPressGesture` hack
- **风格**：温暖精致（Templex 灵感），暖白底色 + 大圆角 + 柔和粉彩点缀

实现文件放在 `DesignSystem/` 目录下：`DKColor.swift`、`DKTypography.swift`、`DKSpacing.swift`、`DKMotion.swift`、`DKShadow.swift`。

## Project Structure Notes

- `SidebarView.SidebarTab` 枚举定义导航标签（overview / issues / prs）
- Issue 看板三列：To Do / In Progress / Done；PR 看板四列：Draft / In Review / Need Fix / Ready
- `CachedIssue` 和 `CachedPR` 使用 `#Unique` 约束避免重复缓存
- `LabelParser` 从 GitHub label 字符串提取 severity / priority / customer 结构化数据
- Settings 通过 macOS 原生 `Settings {}` scene 实现（非自定义窗口）
