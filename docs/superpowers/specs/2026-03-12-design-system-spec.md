# DevKit Design System Specification

> Token-First 设计系统规范，灵感来自 Templex 的温暖精致风格，适配 macOS SwiftUI 原生开发。
> 产出物为开发规范 + 示例代码，而非直接实现。

## 目录

1. [设计理念](#1-设计理念)
2. [色彩系统](#2-色彩系统)
3. [字体系统](#3-字体系统)
4. [间距与圆角系统](#4-间距与圆角系统)
5. [组件规范](#5-组件规范)
6. [动画规范](#6-动画规范)
7. [布局模板](#7-布局模板)
8. [SwiftUI 实现指南](#8-swiftui-实现指南)

---

## 1. 设计理念

### 1.1 定位

DevKit 是一个 Agent 辅助开发应用，不是传统开发者工具。设计应体现：

- **温暖精致** — 暖色基调、大圆角、柔和粉彩，让长时间使用更加舒适
- **编辑式排版** — 通过字体层次和留白节奏传达高级感
- **安静底色 + 精准点缀** — 功能语义色仅出现在小面积徽章/色条上
- **全面微交互** — 每个状态变化都有对应动画反馈

### 1.2 参考

核心视觉参考：Templex（智能税务网页应用），提取其暖白底色、mesh 渐变、大圆角卡片、彩色功能网格、状态列表等特征，适配到 macOS 原生 SwiftUI。

### 1.3 原则

1. **Token 优先** — 所有视觉值通过 Token 定义，禁止硬编码样式
2. **双模式同步** — 浅色（暖白粉彩）+ 深色（暖灰降饱和）同时设计
3. **系统字体极致化** — SF Pro + New York（点睛），零额外包体积
4. **Transform Only 动画** — 仅动画 opacity/scale/offset/rotation/shadow，不动画布局属性
5. **尊重辅助功能** — 减弱动效偏好时退化为纯 opacity 过渡

---

## 2. 色彩系统

### 2.1 Surface 色板

| Token | 浅色模式 | 深色模式 | 用途 |
|-------|---------|---------|------|
| `surface.primary` | `#FAF9F6` | `#1C1B19` | 窗口底色 |
| `surface.secondary` | `#F3F1EC` | `#2A2825` | 列背景、分组背景 |
| `surface.tertiary` | `#ECEAE4` | `#353330` | 嵌套卡片、输入框背景 |
| `surface.card` | `#FFFFFF` | `#322F2B` | 卡片背景 |
| `surface.elevated` | `#FFFFFF` | `#3A3734` | 悬浮/弹出层 |

### 2.2 文字色

| Token | 浅色 | 深色 | 用途 |
|-------|------|------|------|
| `text.primary` | `#1A1A1A` | `#F0EDE8` | 标题、正文 |
| `text.secondary` | `#6B6560` | `#A09A93` | 次要信息、说明 |
| `text.tertiary` | `#9C958E` | `#706A63` | 时间戳、占位符 |
| `text.inverse` | `#FAF9F6` | `#1A1A1A` | 深底上的文字 |

### 2.3 语义色（Severity 点缀）

柔化但可辨识，仅用于小面积徽章/色条/图标圈。

| Token | 色值 | 淡底色（20%） | 用途 |
|-------|------|-------------|------|
| `accent.critical` | `#C4554D` | `#F5E8E5` | s-1 |
| `accent.warning` | `#C48A3F` | `#F3EFDC` | s0 |
| `accent.caution` | `#B5A642` | `#F2F0E0` | s1 |
| `accent.positive` | `#5B9A6D` | `#E4F0E8` | s2 / Done |
| `accent.info` | `#5B7FB5` | `#E3E9F4` | In Progress |
| `accent.brand` | `#8B6CC1` | `#E8DFF5` | 品牌强调、主按钮 |

**深色模式语义色完整色板：**

| Token | 色值（深色） | 淡底色（深色，12%） |
|-------|------------|-------------------|
| `accent.critical` | `#B86B65` | `#3A2C2A` |
| `accent.warning` | `#B8934F` | `#3A3328` |
| `accent.caution` | `#A9A053` | `#35332A` |
| `accent.positive` | `#6BA87A` | `#2A3530` |
| `accent.info` | `#6B8DB8` | `#2A3038` |
| `accent.brand` | `#9A7EC8` | `#302A3A` |

色值计算规则：在 HSB 色彩空间中，饱和度 -20%，亮度不变。淡底色为 accent 色值叠加 12% 不透明度在 `surface.primary` 深色底 `#1C1B19` 上的合成结果。

### 2.4 渐变（Hero 卡片）

```
mesh gradient:
  radial-gradient(at 0% 0%, #E8DFF5)      // 淡紫
  radial-gradient(at 100% 0%, #FCE1D6)    // 淡桃
  radial-gradient(at 100% 100%, #FDF2D0)  // 淡金
  radial-gradient(at 0% 100%, #E0C3FC)    // 淡薰衣草
  底色: surface.card
```

**深色模式渐变色（HSB 空间降饱和 40%、降亮度 60%）：**

```
mesh gradient (dark):
  radial-gradient(at 0% 0%, #3D3548)      // 暗紫
  radial-gradient(at 100% 0%, #4A3A34)    // 暗桃
  radial-gradient(at 100% 100%, #4A4530)  // 暗金
  radial-gradient(at 0% 100%, #3A2E48)    // 暗薰衣草
  底色: surface.card (#322F2B)
```

**SwiftUI MeshGradient 实现（macOS 15+）：**

```swift
// macOS 15+ 使用 MeshGradient
MeshGradient(
    width: 3, height: 3,
    points: [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.5], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1]
    ],
    colors: [
        Color(hex: "#E8DFF5"), Color(hex: "#F0E8EA"), Color(hex: "#FCE1D6"),
        Color(hex: "#E4DDF0"), DKColor.Surface.card, Color(hex: "#F8E8D8"),
        Color(hex: "#E0C3FC"), Color(hex: "#EEE2E0"), Color(hex: "#FDF2D0")
    ]
)
```

---

## 3. 字体系统

### 3.1 字体族

| 用途 | 字体 | SwiftUI Design |
|------|------|----------------|
| 正文/功能文字 | SF Pro | `.default` |
| Hero 大标题（1-2处） | New York | `.serif` |
| 代码/技术文本 | SF Mono | `.monospaced` |

### 3.2 排版阶梯

| Token | 字号 | 字重 | 字距 | 行高 | 用途 |
|-------|------|------|------|------|------|
| `type.heroTitle` | 34pt | Regular | -0.5pt | 1.1 | Overview hero 标题（serif） |
| `type.pageTitle` | 22pt | Semibold | -0.3pt | 1.2 | 页面标题 |
| `type.sectionHeader` | 13pt | Semibold | 1.2pt | 1.3 | 大写区域标题 |
| `type.cardTitle` | 17pt | Medium | -0.2pt | 1.25 | 卡片主标题 |
| `type.body` | 14pt | Regular | 0pt | 1.5 | 正文 |
| `type.bodyMedium` | 14pt | Medium | 0pt | 1.5 | 正文强调 |
| `type.caption` | 12pt | Medium | 0.2pt | 1.4 | 辅助信息、标签 |
| `type.captionSmall` | 11pt | Regular | 0.3pt | 1.4 | 时间戳、最次要信息 |
| `type.issueNumber` | 13pt | Medium | 0pt | 1.0 | Issue 编号（monospaced） |

### 3.3 排版规则

1. **大写字母间距要宽** — `sectionHeader` 用 `tracking: 1.2pt` + 大写，制造编辑式区域标题感
2. **大标题字距要紧** — `heroTitle` 和 `pageTitle` 用负字距，视觉上更紧凑精致
3. **正文行高要松** — `1.5` 行高保证长文可读性
4. **层级靠字重区分** — body 和 bodyMedium 同字号不同字重，避免字号过多
5. **Issue 编号用 monospaced** — `#127` 等编号用等宽字体，和正文形成微妙对比

### 3.4 排版 ViewModifier

由于 SwiftUI 的 `Font` 不支持内嵌 tracking 和 lineSpacing，提供统一的 ViewModifier 封装 font + tracking + lineSpacing 组合，避免调用方遗漏：

```swift
struct DKTextStyle: ViewModifier {
    let font: Font
    let tracking: CGFloat
    let lineSpacing: CGFloat  // 基于字号计算的绝对行距增量

    func body(content: Content) -> some View {
        content
            .font(font)
            .tracking(tracking)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func dkTextStyle(_ style: DKTextStyleToken) -> some View {
        modifier(style.modifier)
    }
}

enum DKTextStyleToken {
    case heroTitle, pageTitle, sectionHeader, cardTitle
    case body, bodyMedium, caption, captionSmall, issueNumber

    var modifier: DKTextStyle {
        switch self {
        case .heroTitle:     DKTextStyle(font: .system(size: 34, design: .serif).weight(.regular), tracking: -0.5, lineSpacing: 34 * 0.1)
        case .pageTitle:     DKTextStyle(font: .system(size: 22, weight: .semibold), tracking: -0.3, lineSpacing: 22 * 0.2)
        case .sectionHeader: DKTextStyle(font: .system(size: 13, weight: .semibold), tracking: 1.2, lineSpacing: 13 * 0.3)
        case .cardTitle:     DKTextStyle(font: .system(size: 17, weight: .medium), tracking: -0.2, lineSpacing: 17 * 0.25)
        case .body:          DKTextStyle(font: .system(size: 14, weight: .regular), tracking: 0, lineSpacing: 14 * 0.5)
        case .bodyMedium:    DKTextStyle(font: .system(size: 14, weight: .medium), tracking: 0, lineSpacing: 14 * 0.5)
        case .caption:       DKTextStyle(font: .system(size: 12, weight: .medium), tracking: 0.2, lineSpacing: 12 * 0.4)
        case .captionSmall:  DKTextStyle(font: .system(size: 11, weight: .regular), tracking: 0.3, lineSpacing: 11 * 0.4)
        case .issueNumber:   DKTextStyle(font: .system(size: 13, weight: .medium, design: .monospaced), tracking: 0, lineSpacing: 0)
        }
    }
}

// 使用
Text("Your Workspace")
    .dkTextStyle(.sectionHeader)
    .textCase(.uppercase)  // sectionHeader 专用，需手动附加
```

> **注意：** `sectionHeader` 样式需额外附加 `.textCase(.uppercase)`，因为 textCase 是视图修饰符而非文本属性，无法封装进 ViewModifier。

---

## 4. 间距与圆角系统

### 4.1 间距阶梯（4pt 基准网格）

| Token | 值 | 用途 |
|-------|-----|------|
| `space.xxs` | 2pt | 图标与文字间微距 |
| `space.xs` | 4pt | 徽章内边距、紧凑元素间 |
| `space.sm` | 8pt | 卡片内元素间距、列表行内 |
| `space.md` | 12pt | 组件间距、卡片内边距 |
| `space.lg` | 16pt | 区域内边距 |
| `space.xl` | 24pt | 区域之间 |
| `space.xxl` | 32pt | 页面顶部/大区块分隔 |
| `space.xxxl` | 48pt | Hero 卡片内大留白 |

### 4.2 圆角阶梯

| Token | 值 | 用途 |
|-------|-----|------|
| `radius.sm` | 6pt | 小徽章、severity badge |
| `radius.md` | 12pt | 按钮、输入框、小卡片 |
| `radius.lg` | 20pt | 标准卡片、列容器 |
| `radius.xl` | 28pt | 大卡片、功能区块 |
| `radius.hero` | 32pt | Hero 卡片、Overview 主区域 |
| `radius.full` | Capsule | 标签、状态指示器 |

### 4.3 阴影阶梯

极轻，暖色阴影。深色模式下不透明度各 +5%。

| Token | 定义 | 用途 |
|-------|------|------|
| `shadow.none` | — | 默认状态下多数组件 |
| `shadow.sm` | `color: #1A1A1A/5%, radius: 2, y: 1` | 静态卡片 |
| `shadow.md` | `color: #1A1A1A/8%, radius: 8, y: 2` | Hover 状态、浮层 |
| `shadow.lg` | `color: #1A1A1A/12%, radius: 16, y: 4` | 弹出菜单、拖拽中的卡片 |

### 4.4 布局节奏规则

1. **卡片内部** — `space.md`(12pt) 内边距 + `space.sm`(8pt) 元素间距
2. **卡片之间** — `space.md`(12pt) 间距
3. **区域之间** — `space.xl`(24pt) 以上
4. **页面边距** — `space.lg`(16pt) 最小
5. **不等距节奏** — 区域标题上方 `space.xxl`(32pt)，下方 `space.md`(12pt)，松→紧呼吸感

---

## 5. 组件规范

### 5.1 Issue 卡片（IssueCard）

核心组件，看板和列表中都会复用。

**结构：**
```
┌─ radius.lg ──────────────────────────┐
│ ┌─ HStack ─────────────────────────┐ │
│ │ #127 (monospaced)    [s-1 badge] │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Issue title goes here and can        │
│ wrap to two lines maximum            │
│                                      │
│ ┌─ HStack ─────────────────────────┐ │
│ │ 🏢 Acme Corp        · 2h ago    │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**样式：**

| 属性 | 值 |
|------|-----|
| 背景 | `surface.card` |
| 圆角 | `radius.lg` (20pt) |
| 内边距 | `space.md` (12pt) |
| 元素间距 | `space.sm` (8pt) |
| 标题字体 | `type.cardTitle`，限 2 行 |
| 编号字体 | `type.issueNumber`，`text.secondary` |
| 底部辅助信息 | `type.captionSmall`，`text.tertiary` |

**状态变化：**

| 状态 | 背景 | 阴影 | 缩放 | 过渡 |
|------|------|------|------|------|
| Default | `surface.card` | `shadow.sm` | 1.0 | — |
| Hover | `surface.card` | `shadow.md` | 1.01 | `.easeOut, 0.2s` |
| Pressed | `surface.card` | `shadow.none` | 0.98 | `.easeOut, 0.1s` |
| Dragging | `surface.elevated` | `shadow.lg` | 1.03 | `.spring(response: 0.3)` |

**Severity 徽章：**

| 属性 | 值 |
|------|-----|
| 背景 | `accent.{level}` 20% 不透明度 |
| 前景 | `accent.{level}` 100% |
| 字体 | `type.captionSmall` |
| 内边距 | `space.xs` 水平, `space.xxs` 垂直 |
| 圆角 | `radius.full` (Capsule) |

### 5.2 看板列（BoardColumn）

**结构：**
```
┌─ radius.xl ─────────────────────┐
│ ┌─ Header ────────────────────┐ │
│ │ To Do                  [12] │ │
│ └─────────────────────────────┘ │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│ ┌─ ScrollView ────────────────┐ │
│ │ ┌─ IssueCard ─────────────┐ │ │
│ │ └─────────────────────────┘ │ │
│ │ ┌─ IssueCard ─────────────┐ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**样式：**

| 属性 | 值 |
|------|-----|
| 背景 | `surface.secondary` |
| 圆角 | `radius.xl` (28pt) |
| 内边距 | `space.md` (12pt) |
| 卡片间距 | `space.sm` (8pt) |
| 标题字体 | `type.bodyMedium` |
| 计数徽章背景 | `surface.tertiary` |
| 计数徽章圆角 | `radius.full` |

**拖放反馈：**

| 状态 | 效果 |
|------|------|
| Drop 目标激活 | 边框 `accent.brand` 50% 不透明度，背景微亮 |
| Drop 释放 | 卡片弹性落入 `.spring(response: 0.4, dampingFraction: 0.7)` |

### 5.3 Hero 概览卡片（OverviewHeroCard）

Overview 页面顶部主视觉区域。

**结构：**
```
┌─ radius.hero ── mesh gradient 背景 ──────────┐
│                                               │
│  ┌─ 胶囊标签 ──────────┐                       │
│  │ workspace name      │                       │
│  └─────────────────────┘                       │
│                                               │
│  Hero Title Here                              │
│  in Serif Font.               (heroTitle)     │
│                                               │
│  Description text...          (body)          │
│                                               │
│  ┌─ HStack ──────────────────────────┐        │
│  │ Tap to view board          ( → )  │        │
│  └───────────────────────────────────┘        │
└───────────────────────────────────────────────┘
```

**样式：**

| 属性 | 值 |
|------|-----|
| 背景 | Mesh gradient（见 2.4） |
| 圆角 | `radius.hero` (32pt) |
| 边框 | 白色 50% 不透明度, 1pt |
| 内边距 | `space.xxxl` 顶部, `space.xl` 其余 |
| 标题字体 | `type.heroTitle` (serif) |
| 描述字体 | `type.body`, `text.secondary` |
| 胶囊标签 | 白色 60% 背景, backdrop blur, 白色 40% 边框 |
| Hover | `scaleEffect(1.008)`, `.easeOut, 0.25s` |

### 5.4 功能网格卡片（FeatureGridCard）

Overview 页面按 severity/customer/维度分类的彩色卡片。

| 属性 | 值 |
|------|-----|
| 背景 | 各 `accent.{type}` 的淡底色 |
| 圆角 | `radius.xl` (28pt) |
| 最小高度 | 180pt（使用 `.frame(minHeight: 180)`，辅助功能大字体模式下自动扩展） |
| 边框 | `surface.secondary` 50% 不透明度 |
| 底部渐变 | 同色系加深 30%，从底部渐变 40% 高度 |
| 标题字体 | `type.cardTitle` |
| 副文字字体 | `type.caption`, `text.secondary` |
| 箭头按钮 | 白色 50% 圆形背景, 40pt |

### 5.5 状态列表行（StatusListRow）

Overview 中展示最近活动。

**结构：**
```
┌─ surface.card, radius.xl ────────────────────┐
│ ┌─ Row (radius.lg, hover) ─────────────────┐ │
│ │ (🟣 icon)  Title           (✓ / → / ⟳)  │ │
│ │            Subtitle                      │ │
│ └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 外容器背景 | `surface.card` |
| 外容器圆角 | `radius.xl` (28pt) |
| 外容器内边距 | `space.xxs` (2pt) |
| 行内边距 | `space.md` (12pt) |
| 行 Hover | `surface.secondary`, `radius.lg` |
| 图标圈 | 48pt, 各 accent 淡底色背景, 对应 accent 前景 |
| 标题字体 | `type.bodyMedium` |
| 副标题字体 | `type.caption`, `text.secondary` |

### 5.6 按钮样式

| 类型 | 背景 | 前景 | 圆角 | 高度 |
|------|------|------|------|------|
| Primary | `accent.brand` | `text.inverse` | `radius.md` | 36pt |
| Secondary | `surface.tertiary` | `text.primary` | `radius.md` | 36pt |
| Ghost | 透明 | `text.secondary` | `radius.md` | 36pt |
| Icon Circle | `surface.secondary` | `text.secondary` | 圆形 | 40pt |

所有按钮状态：
- Hover: 叠加 `Color.white.opacity(0.05)` 覆盖层（浅色模式）或 `Color.white.opacity(0.08)`（深色模式）
- Pressed: `scaleEffect(0.96)`, `motion.spring.stiff`
- Focused: 2pt `accent.brand` 50% 不透明度描边（键盘导航聚焦态）
- Disabled: 40% 不透明度

**推荐使用 `ButtonStyle` 实现按压效果**（比 `onLongPressGesture` hack 更可靠）：

```swift
struct DKButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
    }
}
```

### 5.7 空状态（Empty State）

空状态是教学机会，不是"什么都没有"。

```
┌─ 居中 ─────────────────────────────┐
│       (柔和 SF Symbol)              │
│                                     │
│    「还没有工作空间」                  │
│    type.cardTitle, text.primary     │
│                                     │
│    在设置中添加你的第一个              │
│    GitHub 仓库，开始追踪 Issue        │
│    type.body, text.secondary        │
│                                     │
│    [ 添加工作空间 ]  (Primary btn)   │
└─────────────────────────────────────┘
```

---

## 6. 动画规范

### 6.1 动画曲线 Token

| Token | 定义 | 用途 |
|-------|------|------|
| `motion.spring.default` | `.spring(response: 0.35, dampingFraction: 0.8)` | 通用交互反馈 |
| `motion.spring.bouncy` | `.spring(response: 0.4, dampingFraction: 0.65)` | 拖放落地、弹出 |
| `motion.spring.stiff` | `.spring(response: 0.25, dampingFraction: 0.9)` | 按钮按压、快速反馈 |
| `motion.ease.appear` | `.easeOut(duration: 0.25)` | 元素出现 |
| `motion.ease.disappear` | `.easeIn(duration: 0.15)` | 元素消失 |
| `motion.ease.hover` | `.easeOut(duration: 0.2)` | Hover 状态变化 |

### 6.2 场景动画

#### 卡片 Hover

```swift
@State private var isHovered = false

IssueCardContent()
    .scaleEffect(isHovered ? 1.01 : 1.0)
    .shadow(
        color: Color(red: 0.1, green: 0.1, blue: 0.1).opacity(isHovered ? 0.08 : 0.05),
        radius: isHovered ? 8 : 2,
        y: isHovered ? 2 : 1
    )
    .animation(DKMotion.Ease.hover, value: isHovered)
    .onHover { isHovered = $0 }
```

#### 卡片交错淡入

```swift
ForEach(Array(issues.enumerated()), id: \.element.id) { index, issue in
    IssueCardView(issue: issue)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        ))
        .animation(
            DKMotion.Ease.appear.delay(min(Double(index) * 0.04, 0.4)),
            value: issues.count
        )
}
```

#### 拖放

| 阶段 | 动画 |
|------|------|
| 拾起 | `scaleEffect(1.03)` + `shadow.lg` + `rotationEffect(.degrees(-1.5))`, `spring.default` |
| 悬停在目标列 | 目标列边框淡入 `accent.brand` 50%, `ease.appear` |
| 释放落地 | `scaleEffect(1.0)` + `shadow.sm`, `spring.bouncy` |
| 取消 | 回弹原位, `spring.default` |

#### 视图切换

```swift
switch selectedTab {
case .overview:
    OverviewDashboardView()
        .transition(.opacity.combined(with: .offset(x: -20)))
case .issues:
    IssueBoardView()
        .transition(.opacity.combined(with: .offset(x: 20)))
case .prs:
    Text("Phase 2")
}
.animation(DKMotion.Spring.default, value: selectedTab)
```

#### 数值变化

```swift
Text("\(count)")
    .contentTransition(.numericText(value: Double(count)))
    .animation(DKMotion.Spring.default, value: count)
```

#### Hero 卡片入场

```swift
@State private var appeared = false

HeroCard()
    .opacity(appeared ? 1 : 0)
    .offset(y: appeared ? 0 : 16)
    .scaleEffect(appeared ? 1 : 0.97)
    .animation(DKMotion.Ease.appear.delay(0.1), value: appeared)
    .onAppear { appeared = true }
```

网格卡片在 hero 之后依次入场，每张延迟 0.08s。

#### 按钮按压

推荐使用 `ButtonStyle`（官方 API），而非 `onLongPressGesture` hack：

```swift
struct DKScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
    }
}

// 使用
Button("Action") { /* ... */ }
    .buttonStyle(DKScaleButtonStyle())
```

### 6.3 动画规则

1. **Transform Only** — 仅动画 `opacity`, `scaleEffect`, `offset`, `rotationEffect`, `shadow`，禁止动画 `frame`, `padding`
2. **有意义才动** — 动画必须传达状态变化，禁止纯装饰性循环动画
3. **减弱动效** — 尊重 `@Environment(\.accessibilityReduceMotion)`，为 `true` 时退化为纯 opacity 淡入淡出
4. **不超过 0.4s** — 单个动画体感时长不超过 0.4s
5. **交错上限** — 列表交错最大累计延迟 0.4s，之后所有元素同时出现

---

## 7. 布局模板

### 7.1 应用整体结构

**实施注意：** 当前代码使用 `minWidth: 900, minHeight: 600`，需升级为 `960x640` 以适配新增的 Overview 布局。同时需在 `SidebarTab` 枚举中新增 `.overview` case 并设为默认选中。

```
┌─ Window (minWidth: 960, minHeight: 640) ──────────────────────┐
│ ┌─ NavigationSplitView ─────────────────────────────────────┐ │
│ │ ┌─ Sidebar ─────┐ ┌─ Detail ────────────────────────────┐ │ │
│ │ │ (220pt ideal) │ │                                     │ │ │
│ │ │               │ │  surface.primary 底色                │ │ │
│ │ │ Workspace ▾   │ │                                     │ │ │
│ │ │               │ │  内容区域                             │ │ │
│ │ │ ▸ Overview    │ │  padding: space.lg (16pt)           │ │ │
│ │ │ ▸ Board       │ │                                     │ │ │
│ │ │ ▸ Pull Reqs   │ │                                     │ │ │
│ │ └───────────────┘ └─────────────────────────────────────┘ │ │
│ └───────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

侧边栏：

| 属性 | 值 |
|------|-----|
| 宽度 | `min: 180, ideal: 220, max: 280` |
| Tab 图标 | SF Symbols, `text.secondary` |
| Tab 选中态 | `accent.brand` 前景 |
| Workspace Picker | `type.bodyMedium` |

### 7.2 Overview 仪表盘

从上到下的信息流：概览 → 分类 → 活动明细。

```
┌─ ScrollView ──────────────────────────────────────────────┐
│                                                           │
│  space.xxl (32pt)                                         │
│                                                           │
│  Section Header: ✦ YOUR WORKSPACE     View history →      │
│  space.md (12pt)                                          │
│  ┌─ Hero Card (mesh gradient, radius.hero) ────────────┐  │
│  │  胶囊标签 · workspace name                           │  │
│  │  12 open issues, 3 need attention.  (heroTitle)     │  │
│  │  描述文字...                                         │  │
│  │  Tap to view board                        ( → )    │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  space.xxl (32pt)                                         │
│  Section Header: ◉ BY SEVERITY         View all →         │
│  space.md (12pt)                                          │
│  ┌─ Grid (3 columns, space.md gap) ───────────────────┐  │
│  │  FeatureCard(淡玫瑰)  FeatureCard(淡琥珀)  FeatureCard(淡薄荷) │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  space.xxl (32pt)                                         │
│  Section Header: RECENT ACTIVITY                          │
│  space.md (12pt)                                          │
│  ┌─ StatusListRow container (radius.xl) ───────────────┐  │
│  │  (🟣) Issue #142 opened            · 2h ago         │  │
│  │  (🟠) #138 moved to In Progress    · 4h ago         │  │
│  │  (🟢) #135 resolved                · 1d ago         │  │
│  │  (🔵) New comment on #127          · 2d ago         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

节奏规则：Section Header 上方 `space.xxl`(32pt)，下方 `space.md`(12pt)。

### 7.3 Board 看板

升级版三列 Kanban，视觉全面走 Token：

```
┌─ HStack (space.md gap) ───────────────────────────────────┐
│ ┌─ Column (radius.xl) ─┐ ┌─ Column ────────┐ ┌─ Column ─┐│
│ │ surface.secondary     │ │                 │ │          ││
│ │ To Do           [12]  │ │ In Progress [3] │ │ Done [8] ││
│ │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │ │ ─ ─ ─ ─ ─ ─ ─  │ │ ─ ─ ─ ─ ││
│ │ ┌─ IssueCard ───────┐ │ │                 │ │          ││
│ │ │ radius.lg         │ │ │                 │ │          ││
│ │ │ hover: scale+shad │ │ │                 │ │          ││
│ │ └───────────────────┘ │ │                 │ │          ││
│ └───────────────────────┘ └─────────────────┘ └──────────┘│
└───────────────────────────────────────────────────────────┘
```

### 7.4 Issue Detail

从 GroupBox 堆叠改为独立圆角卡片分段：

```
┌─ ScrollView ──────────────────────────────────────────────┐
│                                                           │
│  Header（无背景，直接铺在 surface.primary 上）               │
│  #127 (monospaced)   [In Progress badge]                  │
│  Issue Title Here (type.pageTitle)                        │
│                                                           │
│  Labels (FlowLayout): [bug] [severity/s-1] [customer/acme]│
│                                                           │
│  ┌─ Metadata Card (surface.card, radius.xl) ──────────┐  │
│  │  Severity · Priority · Customer · Milestone · Updated│  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─ Attachments Card (surface.card, radius.xl) ───────┐  │
│  │  📎 文件列表 + [ Download All ]                      │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  Section Header: COMMENTS (3)                             │
│  ┌─ Comment Card (surface.card, radius.lg) ────────────┐  │
│  │  @alice · 2h ago                                    │  │
│  │  Comment body text...                               │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

区块间距 `space.xl` (24pt)。

---

## 8. SwiftUI 实现指南

### 8.1 Token 代码结构

建议在项目中创建以下文件：

```
DevKit/
├── DesignSystem/
│   ├── DKColor.swift          // 色彩 Token
│   ├── DKTypography.swift     // 字体 Token
│   ├── DKSpacing.swift        // 间距 + 圆角 Token
│   ├── DKMotion.swift         // 动画曲线 Token
│   └── DKShadow.swift         // 阴影 Token
```

### 8.2 色彩 Token 实现

```swift
import SwiftUI

enum DKColor {
    enum Surface {
        static let primary = Color("SurfacePrimary")
        static let secondary = Color("SurfaceSecondary")
        static let tertiary = Color("SurfaceTertiary")
        static let card = Color("SurfaceCard")
        static let elevated = Color("SurfaceElevated")
    }

    /// 命名为 Foreground 而非 Text，避免与 SwiftUI.Text 视图类型混淆
    enum Foreground {
        static let primary = Color("TextPrimary")
        static let secondary = Color("TextSecondary")
        static let tertiary = Color("TextTertiary")
        static let inverse = Color("TextInverse")
    }

    enum Accent {
        static let critical = Color("AccentCritical")
        static let warning = Color("AccentWarning")
        static let caution = Color("AccentCaution")
        static let positive = Color("AccentPositive")
        static let info = Color("AccentInfo")
        static let brand = Color("AccentBrand")

        /// 返回 severity 对应的 accent 颜色
        static func severity(_ level: String) -> Color {
            switch level {
            case "s-1": critical
            case "s0": warning
            case "s1": caution
            case "s2": positive
            default: Color.secondary
            }
        }
    }
}
```

在 Assets.xcassets 中为每个颜色 Token 创建 Color Set，配置 Any Appearance / Dark Appearance 两套色值。

### 8.3 字体 Token 实现

提供两种使用方式：简单场景用 `DKTypography` 获取 Font，需要完整排版控制时用 `dkTextStyle()` ViewModifier（见 3.4 节）。

```swift
enum DKTypography {
    /// 34pt serif — Overview hero 标题专用
    static func heroTitle() -> Font {
        .system(size: 34, design: .serif).weight(.regular)
    }
    static func pageTitle() -> Font {
        .system(size: 22, weight: .semibold)
    }
    static func sectionHeader() -> Font {
        .system(size: 13, weight: .semibold)
    }
    static func cardTitle() -> Font {
        .system(size: 17, weight: .medium)
    }
    static func body() -> Font {
        .system(size: 14, weight: .regular)
    }
    static func bodyMedium() -> Font {
        .system(size: 14, weight: .medium)
    }
    static func caption() -> Font {
        .system(size: 12, weight: .medium)
    }
    static func captionSmall() -> Font {
        .system(size: 11, weight: .regular)
    }
    static func issueNumber() -> Font {
        .system(size: 13, weight: .medium, design: .monospaced)
    }
}
```

> **推荐：** 优先使用 `dkTextStyle()` ViewModifier（见 3.4 节），它会同时应用 font + tracking + lineSpacing，避免遗漏排版参数。`DKTypography` 仅在需要单独获取 Font 值时使用（如传给 `Label` 等不支持 ViewModifier 的场景）。

### 8.4 间距与圆角 Token 实现

```swift
enum DKSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum DKRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let hero: CGFloat = 32
    // radius.full 使用 SwiftUI 的 Capsule() shape，无需数值常量
}
```

### 8.5 动画 Token 实现

```swift
enum DKMotion {
    enum Spring {
        static let `default` = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.65)
        static let stiff = Animation.spring(response: 0.25, dampingFraction: 0.9)
    }
    enum Ease {
        static let appear = Animation.easeOut(duration: 0.25)
        static let disappear = Animation.easeIn(duration: 0.15)
        static let hover = Animation.easeOut(duration: 0.2)
    }
}
```

### 8.6 阴影 Token 实现

```swift
enum DKShadow {
    struct Value: Sendable {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    /// 暖黑基色 #1A1A1A，与规范 4.3 保持一致
    private static let warmBlack = Color(red: 0.1, green: 0.1, blue: 0.1)

    static let none = Value(color: .clear, radius: 0, y: 0)
    static let sm = Value(color: warmBlack.opacity(0.05), radius: 2, y: 1)
    static let md = Value(color: warmBlack.opacity(0.08), radius: 8, y: 2)
    static let lg = Value(color: warmBlack.opacity(0.12), radius: 16, y: 4)
}

extension View {
    func dkShadow(_ shadow: DKShadow.Value) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }
}
```

> **深色模式处理：** 阴影在深色背景上需要更高不透明度才能可见。建议通过 `@Environment(\.colorScheme)` 判断，深色模式下各级不透明度 +5%（sm=10%, md=13%, lg=17%）。

### 8.7 组合示例：Issue 卡片

```swift
struct IssueCardView: View {
    let issue: CachedIssue
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            HStack {
                Text("#\(issue.number)")
                    .font(DKTypography.issueNumber())
                    .foregroundStyle(DKColor.Foreground.secondary)
                Spacer()
                if let severity = issue.severity {
                    severityBadge(severity)
                }
            }

            Text(issue.title)
                .font(DKTypography.cardTitle())
                .foregroundStyle(DKColor.Foreground.primary)
                .lineLimit(2)
                .tracking(-0.2)

            HStack {
                if let customer = issue.customer {
                    Label(customer, systemImage: "building.2")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Foreground.secondary)
                }
                Spacer()
                Text(issue.updatedAt, style: .relative)
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.tertiary)
            }
        }
        .padding(DKSpacing.md)
        .background(DKColor.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
        .dkShadow(isHovered ? .md : .sm)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity)
            .font(DKTypography.captionSmall())
            .padding(.horizontal, DKSpacing.xs)
            .padding(.vertical, DKSpacing.xxs)
            .background(DKColor.Accent.severity(severity).opacity(0.2))
            .foregroundStyle(DKColor.Accent.severity(severity))
            .clipShape(Capsule())
    }
}
```

### 8.8 组合示例：Section Header

```swift
struct DKSectionHeader: View {
    let title: String
    var icon: String? = nil
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack(spacing: DKSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DKColor.Foreground.primary)
                }
                Text(title)
                    .font(DKTypography.sectionHeader())
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
            Spacer()
            if let trailing, let action = trailingAction {
                Button(action: action) {
                    HStack(spacing: DKSpacing.xxs) {
                        Text(trailing)
                            .font(DKTypography.caption())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(DKColor.Foreground.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DKSpacing.xxs)
    }
}

// 使用
DKSectionHeader(
    title: "Your Workspace",
    icon: "sparkles",
    trailing: "View history"
) {
    // action
}
```
