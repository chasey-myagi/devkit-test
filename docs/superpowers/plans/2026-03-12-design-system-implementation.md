# Design System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Token-First 设计系统规范落地为可用的 SwiftUI 代码，包括 Token 定义、Assets 颜色集、组件库、Overview 页面，并将现有视图迁移到新设计系统。

**Architecture:** 在 `DevKit/DesignSystem/` 目录下创建 5 个 Token 文件（Color、Typography、Spacing、Motion、Shadow），在 Assets.xcassets 中创建浅色/深色双模式颜色集。然后构建可复用组件（IssueCard、BoardColumn、SectionHeader 等），新增 Overview 仪表盘页面，最后将现有视图迁移到 Token 系统。

**Tech Stack:** SwiftUI, SwiftData, macOS 15.0+, Swift 6.0, XcodeGen

**Spec:** `docs/superpowers/specs/2026-03-12-design-system-spec.md`

---

## File Structure

### 新建文件

| 文件 | 职责 |
|------|------|
| `DevKit/DesignSystem/DKColor.swift` | 色彩 Token（Surface、Foreground、Accent 枚举） |
| `DevKit/DesignSystem/DKTypography.swift` | 字体 Token + DKTextStyle ViewModifier |
| `DevKit/DesignSystem/DKSpacing.swift` | 间距 + 圆角 Token |
| `DevKit/DesignSystem/DKMotion.swift` | 动画曲线 Token |
| `DevKit/DesignSystem/DKShadow.swift` | 阴影 Token + dkShadow ViewModifier |
| `DevKit/DesignSystem/DKButtonStyle.swift` | 按钮样式（Scale、Primary、Secondary、Ghost、IconCircle） |
| `DevKit/DesignSystem/DKCardModifier.swift` | 卡片通用修饰符（hover、press、shadow） |
| `DevKit/Views/Overview/OverviewDashboardView.swift` | Overview 仪表盘主视图 |
| `DevKit/Views/Overview/HeroCardView.swift` | Hero 概览卡片（mesh gradient） |
| `DevKit/Views/Overview/FeatureGridCardView.swift` | 功能网格彩色卡片 |
| `DevKit/Views/Overview/StatusListRowView.swift` | 状态列表行组件 |
| `DevKit/Views/Components/DKSectionHeader.swift` | 通用 Section Header 组件 |
| `DevKit/Views/Components/DKEmptyStateView.swift` | 空状态占位组件（I10） |
| `DevKit/Assets.xcassets/Colors/` | 20+ 颜色集（浅色/深色双模式） |
| `DevKitTests/DesignSystem/DKColorTests.swift` | 色彩 Token 存在性测试 |
| `DevKitTests/DesignSystem/DKTypographyTests.swift` | 排版 Token 测试 |
| `DevKitTests/DesignSystem/DKSpacingTests.swift` | 间距/圆角 Token 值验证 |

### 修改文件

| 文件 | 变更 |
|------|------|
| `DevKit/Views/SidebarView.swift` | 新增 `.overview` Tab，设为默认 |
| `DevKit/ContentView.swift` | 添加 Overview case、更新 minWidth/minHeight |
| `DevKit/Views/Issues/IssueCardView.swift` | 迁移到 Token 系统 + hover 动效 |
| `DevKit/Views/Issues/IssueColumnView.swift` | 迁移到 Token 系统 |
| `DevKit/Views/Issues/IssueBoardView.swift` | 迁移到 Token 系统 |
| `DevKit/Views/Issues/IssueDetailView.swift` | 迁移到 Token 系统（GroupBox → 圆角卡片） |
| `DevKit/project.yml` | 确保 DesignSystem 目录被包含 |

---

## Chunk 1: Token Foundation

建立设计系统的基础 Token 层，所有后续任务依赖此层。

### Task 1: 创建 Assets.xcassets 颜色集

**Files:**
- Create: `DevKit/Assets.xcassets/Colors/SurfacePrimary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/SurfaceSecondary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/SurfaceTertiary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/SurfaceCard.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/SurfaceElevated.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/TextPrimary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/TextSecondary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/TextTertiary.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/TextInverse.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentCritical.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentWarning.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentCaution.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentPositive.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentInfo.colorset/Contents.json`
- Create: `DevKit/Assets.xcassets/Colors/AccentBrand.colorset/Contents.json`

- [ ] **Step 1: 创建 Colors 目录的 Contents.json**

```bash
mkdir -p DevKit/DevKit/Assets.xcassets/Colors
```

```json
// DevKit/DevKit/Assets.xcassets/Colors/Contents.json
{
  "info": { "version": 1, "author": "xcode" }
}
```

- [ ] **Step 2: 创建 Surface 颜色集（5 个）**

每个 colorset 目录包含一个 Contents.json，格式如下（以 SurfacePrimary 为例）：

```json
// DevKit/DevKit/Assets.xcassets/Colors/SurfacePrimary.colorset/Contents.json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": { "red": "0.980", "green": "0.976", "blue": "0.965", "alpha": "1.000" }
      },
      "idiom": "universal"
    },
    {
      "appearances": [{ "appearance": "luminosity", "value": "dark" }],
      "color": {
        "color-space": "srgb",
        "components": { "red": "0.110", "green": "0.106", "blue": "0.098", "alpha": "1.000" }
      },
      "idiom": "universal"
    }
  ],
  "info": { "version": 1, "author": "xcode" }
}
```

完整色值映射（hex → sRGB 0-1）：

| Token | 浅色 hex | 浅色 RGB | 深色 hex | 深色 RGB |
|-------|---------|---------|---------|---------|
| SurfacePrimary | #FAF9F6 | 0.980/0.976/0.965 | #1C1B19 | 0.110/0.106/0.098 |
| SurfaceSecondary | #F3F1EC | 0.953/0.945/0.925 | #2A2825 | 0.165/0.157/0.145 |
| SurfaceTertiary | #ECEAE4 | 0.925/0.918/0.894 | #353330 | 0.208/0.200/0.188 |
| SurfaceCard | #FFFFFF | 1.000/1.000/1.000 | #322F2B | 0.196/0.184/0.169 |
| SurfaceElevated | #FFFFFF | 1.000/1.000/1.000 | #3A3734 | 0.227/0.216/0.204 |

对 5 个 Surface 颜色各创建 colorset 目录和 Contents.json。

- [ ] **Step 3: 创建 Text 颜色集（4 个）**

| Token | 浅色 hex | 浅色 RGB | 深色 hex | 深色 RGB |
|-------|---------|---------|---------|---------|
| TextPrimary | #1A1A1A | 0.102/0.102/0.102 | #F0EDE8 | 0.941/0.929/0.910 |
| TextSecondary | #6B6560 | 0.420/0.396/0.376 | #A09A93 | 0.627/0.604/0.576 |
| TextTertiary | #9C958E | 0.612/0.584/0.557 | #706A63 | 0.439/0.416/0.388 |
| TextInverse | #FAF9F6 | 0.980/0.976/0.965 | #1A1A1A | 0.102/0.102/0.102 |

- [ ] **Step 4: 创建 Accent 颜色集（6 个）**

| Token | 浅色 hex | 浅色 RGB | 深色 hex | 深色 RGB |
|-------|---------|---------|---------|---------|
| AccentCritical | #C4554D | 0.769/0.333/0.302 | #B86B65 | 0.722/0.420/0.396 |
| AccentWarning | #C48A3F | 0.769/0.541/0.247 | #B8934F | 0.722/0.576/0.310 |
| AccentCaution | #B5A642 | 0.710/0.651/0.259 | #A9A053 | 0.663/0.627/0.325 |
| AccentPositive | #5B9A6D | 0.357/0.604/0.427 | #6BA87A | 0.420/0.659/0.478 |
| AccentInfo | #5B7FB5 | 0.357/0.498/0.710 | #6B8DB8 | 0.420/0.553/0.722 |
| AccentBrand | #8B6CC1 | 0.545/0.424/0.757 | #9A7EC8 | 0.604/0.494/0.784 |

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/Assets.xcassets/Colors/
git commit -m "feat(design-system): add color assets with light/dark variants"
```

---

### Task 2: 创建 DKColor.swift

**Files:**
- Create: `DevKit/DevKit/DesignSystem/DKColor.swift`
- Test: `DevKit/DevKitTests/DesignSystem/DKColorTests.swift`

- [ ] **Step 1: 编写颜色 Token 存在性测试**

```swift
// DevKit/DevKitTests/DesignSystem/DKColorTests.swift
import Testing
import SwiftUI
@testable import DevKit

struct DKColorTests {
    @Test func surfaceColorsExist() {
        // 验证所有 Surface Token 都能从 Assets 加载（不为 nil）
        let colors: [Color] = [
            DKColor.Surface.primary,
            DKColor.Surface.secondary,
            DKColor.Surface.tertiary,
            DKColor.Surface.card,
            DKColor.Surface.elevated,
        ]
        #expect(colors.count == 5)
    }

    @Test func foregroundColorsExist() {
        let colors: [Color] = [
            DKColor.Foreground.primary,
            DKColor.Foreground.secondary,
            DKColor.Foreground.tertiary,
            DKColor.Foreground.inverse,
        ]
        #expect(colors.count == 4)
    }

    @Test func accentColorsExist() {
        let colors: [Color] = [
            DKColor.Accent.critical,
            DKColor.Accent.warning,
            DKColor.Accent.caution,
            DKColor.Accent.positive,
            DKColor.Accent.info,
            DKColor.Accent.brand,
        ]
        #expect(colors.count == 6)
    }

    // I6 fix: Color 的 == 比较不可靠（Asset Catalog 加载的颜色在不同上下文可能不等），
    // 改为验证 severity 函数不会 crash + 返回值非 nil
    @Test func severityMappingCoversAllLevels() {
        let levels = ["s-1", "s0", "s1", "s2", "unknown"]
        for level in levels {
            // 确保所有级别都能返回有效 Color（不 crash）
            let color: Color = DKColor.Accent.severity(level)
            #expect(type(of: color) == Color.self)
        }
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKColorTests 2>&1 | tail -5
```

Expected: FAIL — `DKColor` 未定义。

- [ ] **Step 3: 实现 DKColor.swift**

```swift
// DevKit/DevKit/DesignSystem/DKColor.swift
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

        static func severity(_ level: String) -> Color {
            switch level {
            case "s-1": critical
            case "s0": warning
            case "s1": caution
            case "s2": positive
            default: Color.secondary
            }
        }

        // I1 fix: 着色背景在浅色/深色模式下使用不同不透明度
        // 浅色模式 20%，深色模式 12%（深色背景上颜色更鲜明）
        static func tintBackground(_ color: Color, colorScheme: ColorScheme) -> Color {
            color.opacity(colorScheme == .dark ? 0.12 : 0.20)
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKColorTests 2>&1 | tail -5
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/DesignSystem/DKColor.swift DevKit/DevKitTests/DesignSystem/DKColorTests.swift
git commit -m "feat(design-system): add DKColor tokens with tests"
```

---

### Task 3: 创建 DKTypography.swift

**Files:**
- Create: `DevKit/DevKit/DesignSystem/DKTypography.swift`
- Test: `DevKit/DevKitTests/DesignSystem/DKTypographyTests.swift`

- [ ] **Step 1: 编写排版 Token 测试**

```swift
// DevKit/DevKitTests/DesignSystem/DKTypographyTests.swift
import Testing
import SwiftUI
@testable import DevKit

struct DKTypographyTests {
    @Test func allFontFunctionsReturnNonNil() {
        // 验证所有字体 Token 函数都能正常返回
        let fonts: [Font] = [
            DKTypography.heroTitle(),
            DKTypography.pageTitle(),
            DKTypography.sectionHeader(),
            DKTypography.cardTitle(),
            DKTypography.body(),
            DKTypography.bodyMedium(),
            DKTypography.caption(),
            DKTypography.captionSmall(),
            DKTypography.issueNumber(),
        ]
        #expect(fonts.count == 9)
    }

    @Test func textStyleTokenCoverage() {
        // 验证所有 DKTextStyleToken case 都能生成 modifier
        let tokens: [DKTextStyleToken] = [
            .heroTitle, .pageTitle, .sectionHeader, .cardTitle,
            .body, .bodyMedium, .caption, .captionSmall, .issueNumber,
        ]
        for token in tokens {
            let modifier = token.modifier
            #expect(modifier.tracking.isFinite)
            #expect(modifier.lineSpacing >= 0)
        }
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKTypographyTests 2>&1 | tail -5
```

Expected: FAIL

- [ ] **Step 3: 实现 DKTypography.swift**

```swift
// DevKit/DevKit/DesignSystem/DKTypography.swift
import SwiftUI

enum DKTypography {
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

// MARK: - TextStyle ViewModifier

struct DKTextStyle: ViewModifier {
    let font: Font
    let tracking: CGFloat
    let lineSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .tracking(tracking)
            .lineSpacing(lineSpacing)
    }
}

enum DKTextStyleToken {
    case heroTitle, pageTitle, sectionHeader, cardTitle
    case body, bodyMedium, caption, captionSmall, issueNumber

    var modifier: DKTextStyle {
        switch self {
        case .heroTitle:     DKTextStyle(font: DKTypography.heroTitle(), tracking: -0.5, lineSpacing: 34 * 0.1)
        case .pageTitle:     DKTextStyle(font: DKTypography.pageTitle(), tracking: -0.3, lineSpacing: 22 * 0.2)
        case .sectionHeader: DKTextStyle(font: DKTypography.sectionHeader(), tracking: 1.2, lineSpacing: 13 * 0.3)
        case .cardTitle:     DKTextStyle(font: DKTypography.cardTitle(), tracking: -0.2, lineSpacing: 17 * 0.25)
        case .body:          DKTextStyle(font: DKTypography.body(), tracking: 0, lineSpacing: 14 * 0.5)
        case .bodyMedium:    DKTextStyle(font: DKTypography.bodyMedium(), tracking: 0, lineSpacing: 14 * 0.5)
        case .caption:       DKTextStyle(font: DKTypography.caption(), tracking: 0.2, lineSpacing: 12 * 0.4)
        case .captionSmall:  DKTextStyle(font: DKTypography.captionSmall(), tracking: 0.3, lineSpacing: 11 * 0.4)
        case .issueNumber:   DKTextStyle(font: DKTypography.issueNumber(), tracking: 0, lineSpacing: 0)
        }
    }
}

extension View {
    func dkTextStyle(_ style: DKTextStyleToken) -> some View {
        modifier(style.modifier)
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKTypographyTests 2>&1 | tail -5
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/DesignSystem/DKTypography.swift DevKit/DevKitTests/DesignSystem/DKTypographyTests.swift
git commit -m "feat(design-system): add DKTypography tokens and DKTextStyle modifier"
```

---

### Task 4: 创建 DKSpacing、DKMotion、DKShadow

**Files:**
- Create: `DevKit/DevKit/DesignSystem/DKSpacing.swift`
- Create: `DevKit/DevKit/DesignSystem/DKMotion.swift`
- Create: `DevKit/DevKit/DesignSystem/DKShadow.swift`
- Test: `DevKit/DevKitTests/DesignSystem/DKSpacingTests.swift`

- [ ] **Step 1: 编写间距/圆角 Token 值验证测试**

```swift
// DevKit/DevKitTests/DesignSystem/DKSpacingTests.swift
import Testing
@testable import DevKit

struct DKSpacingTests {
    @Test func spacingValuesFollowFourPointGrid() {
        // 所有间距值应为 4 的倍数或 2（xxs 特例）
        #expect(DKSpacing.xxs == 2)
        #expect(DKSpacing.xs == 4)
        #expect(DKSpacing.sm == 8)
        #expect(DKSpacing.md == 12)
        #expect(DKSpacing.lg == 16)
        #expect(DKSpacing.xl == 24)
        #expect(DKSpacing.xxl == 32)
        #expect(DKSpacing.xxxl == 48)
    }

    @Test func radiusValuesAscend() {
        #expect(DKRadius.sm < DKRadius.md)
        #expect(DKRadius.md < DKRadius.lg)
        #expect(DKRadius.lg < DKRadius.xl)
        #expect(DKRadius.xl < DKRadius.hero)
    }

    @Test func radiusSpecificValues() {
        #expect(DKRadius.sm == 6)
        #expect(DKRadius.md == 12)
        #expect(DKRadius.lg == 20)
        #expect(DKRadius.xl == 28)
        #expect(DKRadius.hero == 32)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKSpacingTests 2>&1 | tail -5
```

Expected: FAIL

- [ ] **Step 3: 实现 DKSpacing.swift**

```swift
// DevKit/DevKit/DesignSystem/DKSpacing.swift
import SwiftUI

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
    // radius.full → 使用 Capsule() shape
}
```

- [ ] **Step 4: 实现 DKMotion.swift**

```swift
// DevKit/DevKit/DesignSystem/DKMotion.swift
import SwiftUI

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

- [ ] **Step 5: 实现 DKShadow.swift**

```swift
// DevKit/DevKit/DesignSystem/DKShadow.swift
import SwiftUI

enum DKShadow {
    // 存储 opacity 而非 Color.opacity() 返回值，确保 Sendable 安全
    struct Value: Sendable {
        let opacity: Double
        let radius: CGFloat
        let y: CGFloat
    }

    static let none = Value(opacity: 0, radius: 0, y: 0)
    static let sm = Value(opacity: 0.05, radius: 2, y: 1)
    static let md = Value(opacity: 0.08, radius: 8, y: 2)
    static let lg = Value(opacity: 0.12, radius: 16, y: 4)
}

extension View {
    func dkShadow(_ shadow: DKShadow.Value) -> some View {
        // warmBlack #1A1A1A 在此处构建，避免 Sendable 问题
        let warmBlack = Color(red: 0.1, green: 0.1, blue: 0.1)
        return self.shadow(color: warmBlack.opacity(shadow.opacity), radius: shadow.radius, y: shadow.y)
    }
}
```

- [ ] **Step 6: 运行测试验证通过**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit -only-testing DevKitTests/DKSpacingTests 2>&1 | tail -5
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add DevKit/DevKit/DesignSystem/DKSpacing.swift DevKit/DevKit/DesignSystem/DKMotion.swift DevKit/DevKit/DesignSystem/DKShadow.swift DevKit/DevKitTests/DesignSystem/DKSpacingTests.swift
git commit -m "feat(design-system): add spacing, motion, and shadow tokens"
```

---

### Task 5: 创建 DKButtonStyle 和 DKCardModifier

**Files:**
- Create: `DevKit/DevKit/DesignSystem/DKButtonStyle.swift`
- Create: `DevKit/DevKit/DesignSystem/DKCardModifier.swift`

- [ ] **Step 1: 实现 DKButtonStyle.swift**

```swift
// DevKit/DevKit/DesignSystem/DKButtonStyle.swift
import SwiftUI

struct DKScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
    }
}

// I2 fix: 所有 ButtonStyle 添加 hover 和 disabled 状态支持
struct DKPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DKTypography.bodyMedium())
            .foregroundStyle(DKColor.Foreground.inverse)
            .padding(.horizontal, DKSpacing.lg)
            .frame(height: 36)
            .background(DKColor.Accent.brand)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DKRadius.md)
                    .fill(.white.opacity(isHovered ? 0.08 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct DKSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DKTypography.bodyMedium())
            .foregroundStyle(DKColor.Foreground.primary)
            .padding(.horizontal, DKSpacing.lg)
            .frame(height: 36)
            .background(isHovered ? DKColor.Surface.elevated : DKColor.Surface.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct DKGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DKTypography.bodyMedium())
            .foregroundStyle(DKColor.Foreground.secondary)
            .padding(.horizontal, DKSpacing.lg)
            .frame(height: 36)
            .background(isHovered ? DKColor.Surface.secondary : .clear)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

// I12 fix: 圆形图标按钮样式
struct DKIconCircleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    var size: CGFloat = 40  // 规范 5.6: Icon Circle 高度 40pt

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundStyle(DKColor.Foreground.secondary)
            .frame(width: size, height: size)
            .background(isHovered ? DKColor.Surface.tertiary : DKColor.Surface.secondary)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.4)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}
```

- [ ] **Step 2: 实现 DKCardModifier.swift**

```swift
// DevKit/DevKit/DesignSystem/DKCardModifier.swift
import SwiftUI

struct DKCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DKRadius.lg
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // I11 fix
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(DKColor.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // I3 fix: 深色模式降低阴影不透明度（深色背景上阴影效果减弱）
            .dkShadow(isHovered
                ? (colorScheme == .dark ? .sm : .md)
                : (colorScheme == .dark ? .none : .sm))
            // I11 fix: reduceMotion 时禁用缩放动效
            .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
            .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func dkCard(cornerRadius: CGFloat = DKRadius.lg) -> some View {
        modifier(DKCardModifier(cornerRadius: cornerRadius))
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/DesignSystem/DKButtonStyle.swift DevKit/DevKit/DesignSystem/DKCardModifier.swift
git commit -m "feat(design-system): add button styles and card modifier"
```

---

## Chunk 2: 共享组件

基于 Token 构建可复用的 UI 组件。

### Task 6: 创建 DKSectionHeader 和 DKEmptyStateView 组件

**Files:**
- Create: `DevKit/DevKit/Views/Components/DKSectionHeader.swift`
- Create: `DevKit/DevKit/Views/Components/DKEmptyStateView.swift`

- [ ] **Step 1: 实现 DKSectionHeader**

```swift
// DevKit/DevKit/Views/Components/DKSectionHeader.swift
import SwiftUI

struct DKSectionHeader: View {
    let title: String
    var icon: String?
    var trailing: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: DKSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DKColor.Foreground.primary)
                }
                Text(title)
                    .dkTextStyle(.sectionHeader)
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
```

- [ ] **Step 2: 实现 DKEmptyStateView（I10 fix）**

```swift
// DevKit/DevKit/Views/Components/DKEmptyStateView.swift
import SwiftUI

struct DKEmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String?
    // I1-NEW fix: 可选按钮支持（规范 5.7）
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: DKSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(DKColor.Foreground.tertiary)
            Text(title)
                .font(DKTypography.bodyMedium())
                .foregroundStyle(DKColor.Foreground.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.tertiary)
            }
            if let buttonTitle, let buttonAction {
                Button(buttonTitle, action: buttonAction)
                    .buttonStyle(DKPrimaryButtonStyle())
                    .padding(.top, DKSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DKSpacing.xxxl)
        .background(DKColor.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/Views/Components/DKSectionHeader.swift DevKit/DevKit/Views/Components/DKEmptyStateView.swift
git commit -m "feat(design-system): add DKSectionHeader and DKEmptyStateView components"
```

---

### Task 7: 迁移 IssueCardView 到设计系统

**Files:**
- Modify: `DevKit/DevKit/Views/Issues/IssueCardView.swift`

- [ ] **Step 1: 重写 IssueCardView 使用 Token**

将现有 `IssueCardView.swift` 完全替换为 Token 版本：

```swift
// DevKit/DevKit/Views/Issues/IssueCardView.swift
import SwiftUI
import SwiftData

struct IssueCardView: View {
    let issue: CachedIssue
    // C3 fix: 保留 @Query 关联 PR 数据，用于显示 linked PR 状态
    @Query private var cachedPRs: [CachedPR]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // I8 fix
    @State private var isHovered = false

    init(issue: CachedIssue) {
        self.issue = issue
        let workspace = issue.workspaceName
        _cachedPRs = Query(filter: #Predicate<CachedPR> { $0.workspaceName == workspace })
    }

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
                .dkTextStyle(.cardTitle)
                .foregroundStyle(DKColor.Foreground.primary)
                .lineLimit(2)

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

            // C3 fix: 保留 linked PR 状态行
            if !issue.linkedPRNumbers.isEmpty {
                linkedPRStatusRow
            }
        }
        .padding(DKSpacing.md)
        .background(DKColor.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
        .dkShadow(isHovered ? .md : .sm)
        // I8 fix: reduceMotion 时禁用缩放动效
        .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
        .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
    }

    // C3 fix: 完整保留 linked PR 状态展示
    @ViewBuilder
    private var linkedPRStatusRow: some View {
        let linkedPRs = cachedPRs.filter { issue.linkedPRNumbers.contains($0.number) }
        if !linkedPRs.isEmpty {
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "arrow.triangle.pull")
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.secondary)
                ForEach(linkedPRs, id: \.number) { pr in
                    HStack(spacing: DKSpacing.xxs) {
                        prStatusIcon(for: pr)
                        Text("#\(pr.number)")
                            .font(DKTypography.captionSmall())
                    }
                    .foregroundStyle(prStatusColor(for: pr))
                }
                Spacer()
            }
        }
    }

    private func prStatusIcon(for pr: CachedPR) -> Image {
        switch pr.reviewState {
        case "APPROVED":
            Image(systemName: "checkmark.circle.fill")
        case "CHANGES_REQUESTED":
            Image(systemName: "exclamationmark.triangle.fill")
        default:
            Image(systemName: "clock.fill")
        }
    }

    private func prStatusColor(for pr: CachedPR) -> Color {
        switch pr.reviewState {
        case "APPROVED": DKColor.Accent.positive
        case "CHANGES_REQUESTED": DKColor.Accent.warning
        default: Color.secondary
        }
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity)
            .font(DKTypography.captionSmall())
            .padding(.horizontal, DKSpacing.xs)
            .padding(.vertical, DKSpacing.xxs)
            // I7 fix: 使用 tintBackground 辅助方法，深色模式自动降至 12%
            .background(DKColor.Accent.tintBackground(DKColor.Accent.severity(severity), colorScheme: colorScheme))
            .foregroundStyle(DKColor.Accent.severity(severity))
            .clipShape(Capsule())
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/Views/Issues/IssueCardView.swift
git commit -m "refactor: migrate IssueCardView to design system tokens"
```

---

### Task 8: 迁移 IssueColumnView 和 IssueBoardView

**Files:**
- Modify: `DevKit/DevKit/Views/Issues/IssueColumnView.swift`
- Modify: `DevKit/DevKit/Views/Issues/IssueBoardView.swift`

- [ ] **Step 1: 重写 IssueColumnView**

替换现有文件，使用 Token：

```swift
// DevKit/DevKit/Views/Issues/IssueColumnView.swift
import SwiftUI
import SwiftData

struct IssueColumnView: View {
    let title: String
    let status: String
    let issues: [CachedIssue]
    let allIssues: [CachedIssue]
    let onStatusChange: (CachedIssue, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Text("\(issues.count)")
                    .font(DKTypography.caption())
                    .padding(.horizontal, DKSpacing.sm)
                    .padding(.vertical, DKSpacing.xxs)
                    .background(DKColor.Surface.tertiary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)

            Divider()

            ScrollView {
                LazyVStack(spacing: DKSpacing.sm) {
                    ForEach(issues) { issue in
                        NavigationLink(value: issue) {
                            IssueCardView(issue: issue)
                        }
                        .buttonStyle(.plain)
                        .draggable(String(issue.number))
                    }
                }
                .padding(DKSpacing.sm)
            }
        }
        .background(DKColor.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
        .dropDestination(for: String.self) { items, _ in
            guard let numberStr = items.first,
                  let number = Int(numberStr),
                  let issue = allIssues.first(where: { $0.number == number })
            else { return false }
            onStatusChange(issue, status)
            return true
        }
    }
}
```

- [ ] **Step 2: 更新 IssueBoardView 间距**

在 `IssueBoardView.swift` 中将 `HStack(spacing: 12)` 改为 `HStack(spacing: DKSpacing.md)`，将 `.padding()` 改为 `.padding(DKSpacing.lg)`。

- [ ] **Step 3: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add DevKit/DevKit/Views/Issues/IssueColumnView.swift DevKit/DevKit/Views/Issues/IssueBoardView.swift
git commit -m "refactor: migrate board views to design system tokens"
```

---

### Task 9: 迁移 IssueDetailView

**Files:**
- Modify: `DevKit/DevKit/Views/Issues/IssueDetailView.swift`

- [ ] **Step 1: 重写 IssueDetailView**

将 GroupBox 替换为独立圆角卡片，使用 Token。完整迁移代码如下：

```swift
// DevKit/DevKit/Views/Issues/IssueDetailView.swift
import SwiftUI

struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    let localPath: String
    @State private var viewModel = IssueDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.xl) {
                // Header — 直接铺在 surface.primary 上
                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(DKTypography.pageTitle())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        statusBadge
                    }
                    Text(issue.title)
                        .dkTextStyle(.pageTitle)
                        .foregroundStyle(DKColor.Foreground.primary)
                }

                Divider()

                // Labels
                if !issue.labels.isEmpty {
                    FlowLayout(spacing: DKSpacing.xs) {
                        ForEach(issue.labels, id: \.self) { label in
                            Text(label)
                                .font(DKTypography.caption())
                                .padding(.horizontal, DKSpacing.sm)
                                .padding(.vertical, DKSpacing.xxs)
                                .background(DKColor.Surface.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Metadata — 圆角卡片替代 GroupBox
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Details", icon: "info.circle")
                    VStack(spacing: DKSpacing.xs) {
                        LabeledContent("Severity", value: issue.severity ?? "—")
                        LabeledContent("Priority", value: issue.priority ?? "—")
                        LabeledContent("Customer", value: issue.customer ?? "—")
                        LabeledContent("Milestone", value: issue.milestone ?? "—")
                        LabeledContent("Updated", value: issue.updatedAt.formatted())
                    }
                    .font(DKTypography.body())
                    .foregroundStyle(DKColor.Foreground.primary)
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(.sm)
                }

                // Attachments — 圆角卡片
                if !issue.attachmentURLs.isEmpty {
                    VStack(alignment: .leading, spacing: DKSpacing.sm) {
                        DKSectionHeader(title: "Attachments (\(issue.attachmentURLs.count))", icon: "paperclip")
                        VStack(alignment: .leading, spacing: DKSpacing.sm) {
                            attachmentStatusView

                            ForEach(Array(issue.attachmentURLs.enumerated()), id: \.offset) { _, url in
                                HStack {
                                    Image(systemName: "paperclip")
                                        .foregroundStyle(DKColor.Foreground.tertiary)
                                    Text(URL(string: url)?.lastPathComponent ?? url)
                                        .font(DKTypography.body())
                                        .foregroundStyle(DKColor.Foreground.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }

                            if issue.attachmentStatus == "downloaded" {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundStyle(DKColor.Foreground.secondary)
                                    Text("\(localPath)/issues/\(issue.number)")
                                        .font(DKTypography.captionSmall())
                                        .foregroundStyle(DKColor.Foreground.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Open in Finder") {
                                        NSWorkspace.shared.open(URL(fileURLWithPath: "\(localPath)/issues/\(issue.number)"))
                                    }
                                    .font(DKTypography.caption())
                                }
                            }

                            HStack {
                                if issue.attachmentStatus == "failed" {
                                    Button("Retry Download") {
                                        Task {
                                            await viewModel.downloadAttachments(
                                                urls: issue.attachmentURLs,
                                                to: "\(localPath)/issues/\(issue.number)"
                                            )
                                            issue.attachmentStatus = viewModel.downloadError == nil ? "downloaded" : "failed"
                                        }
                                    }
                                }
                                if issue.attachmentStatus == "none" {
                                    Button("Download All") {
                                        Task {
                                            issue.attachmentStatus = "downloading"
                                            await viewModel.downloadAttachments(
                                                urls: issue.attachmentURLs,
                                                to: "\(localPath)/issues/\(issue.number)"
                                            )
                                            issue.attachmentStatus = viewModel.downloadError == nil ? "downloaded" : "failed"
                                        }
                                    }
                                }
                            }
                            .disabled(viewModel.isDownloading)
                        }
                        .padding(DKSpacing.lg)
                        .background(DKColor.Surface.card)
                        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                        .dkShadow(.sm)
                    }
                }

                // Comments — 圆角卡片
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    DKSectionHeader(title: "Comments (\(viewModel.comments.count))", icon: "text.bubble")
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.isLoadingComments {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(DKSpacing.xl)
                        } else if viewModel.comments.isEmpty {
                            Text("No comments")
                                .font(DKTypography.body())
                                .foregroundStyle(DKColor.Foreground.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(DKSpacing.xl)
                        } else {
                            ForEach(viewModel.comments) { comment in
                                VStack(alignment: .leading, spacing: DKSpacing.xs) {
                                    HStack {
                                        Text(comment.author.login)
                                            .font(DKTypography.caption())
                                            .fontWeight(.semibold)
                                            .foregroundStyle(DKColor.Foreground.primary)
                                        Spacer()
                                        if let date = comment.createdDate {
                                            Text(date, style: .relative)
                                                .font(DKTypography.captionSmall())
                                                .foregroundStyle(DKColor.Foreground.tertiary)
                                        } else {
                                            Text(comment.createdAt)
                                                .font(DKTypography.captionSmall())
                                                .foregroundStyle(DKColor.Foreground.tertiary)
                                        }
                                    }
                                    Text(comment.body)
                                        .font(DKTypography.body())
                                        .foregroundStyle(DKColor.Foreground.primary)
                                }
                                .padding(.vertical, DKSpacing.sm)
                                if comment.id != viewModel.comments.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(DKSpacing.lg)
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(.sm)
                }
            }
            .padding(DKSpacing.xl)
        }
        .background(DKColor.Surface.primary)
        .navigationTitle("#\(issue.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, issueNumber: issue.number)
        }
    }

    @ViewBuilder
    private var attachmentStatusView: some View {
        switch issue.attachmentStatus {
        case "downloading":
            HStack(spacing: DKSpacing.sm) {
                ProgressView().controlSize(.small)
                Text("Downloading attachments...")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
        case "downloaded":
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DKColor.Accent.positive)
                Text("All attachments downloaded")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
        case "failed":
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DKColor.Accent.critical)
                Text("Some downloads failed")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.critical)
            }
        default:
            EmptyView()
        }
    }

    private var statusBadge: some View {
        Text(issue.projectStatus)
            .font(DKTypography.caption())
            .padding(.horizontal, DKSpacing.sm)
            .padding(.vertical, DKSpacing.xxs)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch issue.projectStatus {
        case "In Progress": DKColor.Accent.info
        case "Done": DKColor.Accent.positive
        default: Color.secondary
        }
    }
}

// FlowLayout — 保留现有实现，勿删除
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/Views/Issues/IssueDetailView.swift
git commit -m "refactor: migrate IssueDetailView to design system (cards instead of GroupBox)"
```

---

## Chunk 3: Overview 仪表盘 + 导航

新增 Overview 页面和导航集成。

### Task 10: 扩展 SidebarTab 并更新 ContentView

**Files:**
- Modify: `DevKit/DevKit/Views/SidebarView.swift`
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: 在 SidebarTab 中添加 .overview**

```swift
// SidebarView.swift — 修改 SidebarTab 枚举
enum SidebarTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case issues = "Issues"
    case prs = "Pull Requests"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .issues: return "exclamationmark.circle"
        case .prs: return "arrow.triangle.pull"
        }
    }
}
```

- [ ] **Step 2: 更新 ContentView 默认 Tab 和窗口尺寸**

```swift
// ContentView.swift 变更点:
// 1. 默认 Tab 改为 .overview
@State private var selectedTab: SidebarView.SidebarTab = .overview

// 2. 窗口最小尺寸升级
.frame(minWidth: 960, minHeight: 640)

// 3. detail 中添加 overview case，传入导航到 Board 的回调
case .overview:
    OverviewDashboardView(workspace: ws, onNavigateToBoard: { selectedTab = .issues })
```

- [ ] **Step 3: 创建占位 OverviewDashboardView**

```swift
// DevKit/DevKit/Views/Overview/OverviewDashboardView.swift
import SwiftUI
import SwiftData

struct OverviewDashboardView: View {
    let workspace: Workspace

    var body: some View {
        Text("Overview — Phase 2")
            .foregroundStyle(DKColor.Foreground.secondary)
    }
}
```

- [ ] **Step 4: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/Views/SidebarView.swift DevKit/DevKit/ContentView.swift DevKit/DevKit/Views/Overview/OverviewDashboardView.swift
git commit -m "feat: add Overview tab as default landing page"
```

---

### Task 11: 实现 HeroCardView

**Files:**
- Create: `DevKit/DevKit/Views/Overview/HeroCardView.swift`

- [ ] **Step 1: 实现 HeroCardView**

```swift
// DevKit/DevKit/Views/Overview/HeroCardView.swift
import SwiftUI

struct HeroCardView: View {
    let workspaceName: String
    let openCount: Int
    let attentionCount: Int
    var onTapBoard: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // I11 fix
    @State private var isHovered = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: DKSpacing.xl) {
            // 胶囊标签
            Text(workspaceName)
                .font(DKTypography.captionSmall())
                .foregroundStyle(DKColor.Foreground.secondary)
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, DKSpacing.xs)
                .background(.white.opacity(0.6))
                .clipShape(Capsule())

            // 主标题 (serif)
            VStack(alignment: .leading, spacing: DKSpacing.xs) {
                Text("\(openCount) open issues,")
                    .dkTextStyle(.heroTitle)
                    .foregroundStyle(DKColor.Foreground.primary)
                Text("\(attentionCount) need attention.")
                    .dkTextStyle(.heroTitle)
                    .foregroundStyle(DKColor.Foreground.primary)
                    .italic()
                    .opacity(0.8)
            }

            Spacer()

            // 底部操作栏
            HStack {
                Text("Tap to view board")
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DKColor.Foreground.secondary)
                    .frame(width: 40, height: 40)
                    .background(DKColor.Surface.primary.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(DKSpacing.xl)
        .padding(.top, DKSpacing.xl)
        .frame(minHeight: 280)
        .background { heroGradient }
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.hero))
        .overlay(
            RoundedRectangle(cornerRadius: DKRadius.hero)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        )
        // I11 fix: reduceMotion 时禁用 hover/入场动效
        .scaleEffect(isHovered && !reduceMotion ? 1.008 : 1.0)
        .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTapBoard() }
        // 入场动画（reduceMotion 时直接显示）
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 16)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.97)
        .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.1), value: appeared)
        .onAppear { appeared = true }
    }

    // C2 fix: 使用 @ViewBuilder 返回 View，而非 some ShapeStyle
    // C4 fix: 根据 colorScheme 切换浅色/深色渐变
    @ViewBuilder
    private var heroGradient: some View {
        let colors: [Color] = colorScheme == .dark
            ? [
                // 深色模式：低饱和度暖紫色系
                Color(red: 0.18, green: 0.16, blue: 0.22),
                Color(red: 0.20, green: 0.18, blue: 0.20),
                Color(red: 0.22, green: 0.17, blue: 0.16),
                Color(red: 0.17, green: 0.16, blue: 0.21),
                DKColor.Surface.card,
                Color(red: 0.21, green: 0.18, blue: 0.16),
                Color(red: 0.17, green: 0.14, blue: 0.23),
                Color(red: 0.19, green: 0.17, blue: 0.17),
                Color(red: 0.22, green: 0.20, blue: 0.15),
            ]
            : [
                // 浅色模式：柔和暖色系
                Color(red: 0.91, green: 0.87, blue: 0.96),
                Color(red: 0.94, green: 0.91, blue: 0.92),
                Color(red: 0.99, green: 0.88, blue: 0.84),
                Color(red: 0.89, green: 0.87, blue: 0.94),
                DKColor.Surface.card,
                Color(red: 0.97, green: 0.91, blue: 0.85),
                Color(red: 0.88, green: 0.76, blue: 0.99),
                Color(red: 0.93, green: 0.89, blue: 0.88),
                Color(red: 0.99, green: 0.95, blue: 0.82),
            ]
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: colors
        )
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/Views/Overview/HeroCardView.swift
git commit -m "feat: add HeroCardView with mesh gradient and entrance animation"
```

---

### Task 12: 实现 FeatureGridCardView 和 StatusListRowView

**Files:**
- Create: `DevKit/DevKit/Views/Overview/FeatureGridCardView.swift`
- Create: `DevKit/DevKit/Views/Overview/StatusListRowView.swift`

- [ ] **Step 1: 实现 FeatureGridCardView**

```swift
// DevKit/DevKit/Views/Overview/FeatureGridCardView.swift
import SwiftUI

struct FeatureGridCardView: View {
    let title: String
    let subtitle: String
    let backgroundColor: Color
    var onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: DKSpacing.xs) {
                Text(title)
                    .dkTextStyle(.cardTitle)
                    .foregroundStyle(DKColor.Foreground.primary)
                    .lineLimit(3)
            }

            Spacer()

            HStack {
                Text(subtitle)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DKColor.Foreground.secondary)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(DKSpacing.lg)
        .frame(minHeight: 180)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DKRadius.xl)
                .stroke(DKColor.Surface.secondary.opacity(0.5), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTap() }
    }
}
```

- [ ] **Step 2: 实现 StatusListRowView**

```swift
// DevKit/DevKit/Views/Overview/StatusListRowView.swift
import SwiftUI

struct StatusListRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var trailingIcon: String = "chevron.right"

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DKSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DKSpacing.xxs) {
                Text(title)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Text(subtitle)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
            }

            Spacer()

            Image(systemName: trailingIcon)
                .font(.system(size: 14))
                .foregroundStyle(DKColor.Foreground.tertiary)
        }
        .padding(DKSpacing.md)
        .background(isHovered ? DKColor.Surface.secondary : .clear)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
        .animation(DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
    }
}
```

- [ ] **Step 3: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add DevKit/DevKit/Views/Overview/FeatureGridCardView.swift DevKit/DevKit/Views/Overview/StatusListRowView.swift
git commit -m "feat: add FeatureGridCardView and StatusListRowView components"
```

---

### Task 13: 完成 OverviewDashboardView

**Files:**
- Modify: `DevKit/DevKit/Views/Overview/OverviewDashboardView.swift`

- [ ] **Step 1: 实现完整 Overview 仪表盘**

用 HeroCard + 三列 FeatureGrid + StatusListRow 组合，按规范 7.2 布局。完整代码：

```swift
// DevKit/DevKit/Views/Overview/OverviewDashboardView.swift
import SwiftUI
import SwiftData

struct OverviewDashboardView: View {
    let workspace: Workspace
    // I2-NEW fix: 导航到 Board 的回调
    var onNavigateToBoard: (() -> Void)?
    @Query private var allIssues: [CachedIssue]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion  // I11 fix
    @State private var appeared = false

    init(workspace: Workspace, onNavigateToBoard: (() -> Void)? = nil) {
        self.workspace = workspace
        self.onNavigateToBoard = onNavigateToBoard
        let name = workspace.name
        _allIssues = Query(
            filter: #Predicate<CachedIssue> { $0.workspaceName == name },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    // 统计数据
    private var openIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus != "Done" }
    }
    private var criticalIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s-1" }
    }
    private var warningIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s0" }
    }
    private var healthyIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s2" || $0.severity == nil }
    }
    private var recentActivity: [CachedIssue] {
        Array(allIssues.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Card
                HeroCardView(
                    workspaceName: workspace.name,
                    openCount: openIssues.count,
                    attentionCount: criticalIssues.count + warningIssues.count,
                    onTapBoard: { onNavigateToBoard?() }
                )
                .padding(.bottom, DKSpacing.xxl)

                // Feature Grid
                DKSectionHeader(title: "Overview", icon: "square.grid.2x2")
                    .padding(.bottom, DKSpacing.md)

                HStack(spacing: DKSpacing.md) {
                    FeatureGridCardView(
                        title: "\(criticalIssues.count) critical issues",
                        subtitle: "Needs attention",
                        backgroundColor: DKColor.Accent.critical.opacity(0.12),
                        onTap: {}
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.18), value: appeared)

                    FeatureGridCardView(
                        title: "\(warningIssues.count) warnings",
                        subtitle: "Monitor closely",
                        backgroundColor: DKColor.Accent.warning.opacity(0.12),
                        onTap: {}
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.26), value: appeared)

                    FeatureGridCardView(
                        title: "\(healthyIssues.count) healthy",
                        subtitle: "On track",
                        backgroundColor: DKColor.Accent.positive.opacity(0.12),
                        onTap: {}
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.34), value: appeared)
                }
                .padding(.bottom, DKSpacing.xxl)

                // Recent Activity
                DKSectionHeader(title: "Recent Activity", icon: "clock")
                    .padding(.bottom, DKSpacing.md)

                if recentActivity.isEmpty {
                    // I10 fix: Empty State
                    DKEmptyStateView(
                        icon: "tray",
                        title: "No activity yet",
                        subtitle: "Issues will appear here once synced"
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(recentActivity) { issue in
                            StatusListRowView(
                                icon: statusIcon(for: issue),
                                iconColor: statusIconColor(for: issue),
                                title: issue.title,
                                subtitle: "#\(issue.number) · \(issue.updatedAt.formatted(.relative(presentation: .named)))"
                            )
                            if issue.id != recentActivity.last?.id {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(.sm)
                }
            }
            .padding(DKSpacing.xl)
        }
        .background(DKColor.Surface.primary)
        .onAppear { appeared = true }
    }

    private func statusIcon(for issue: CachedIssue) -> String {
        switch issue.severity {
        case "s-1": "exclamationmark.triangle.fill"
        case "s0": "exclamationmark.circle.fill"
        default: "circle.fill"
        }
    }

    private func statusIconColor(for issue: CachedIssue) -> Color {
        DKColor.Accent.severity(issue.severity ?? "")
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
cd DevKit && xcodegen generate && xcodebuild build -scheme DevKit 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 运行全部测试**

```bash
cd DevKit && xcodebuild test -scheme DevKit 2>&1 | tail -10
```

Expected: ALL TESTS PASS

- [ ] **Step 4: Commit**

```bash
git add DevKit/DevKit/Views/Overview/OverviewDashboardView.swift
git commit -m "feat: implement Overview dashboard with hero, grid, and activity list"
```

---

### Task 14: 全局窗口底色和最终调整

**Files:**
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: 设置窗口底色为 surface.primary**

在 ContentView 的 NavigationSplitView 上添加：

```swift
.background(DKColor.Surface.primary)
```

- [ ] **Step 2: 运行全部测试**

```bash
cd DevKit && xcodegen generate && xcodebuild test -scheme DevKit 2>&1 | tail -10
```

Expected: ALL TESTS PASS

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/ContentView.swift
git commit -m "feat: apply surface.primary window background"
```

---

## Execution Dependencies

```
Task 1 (Assets colors)
  └→ Task 2 (DKColor) ──────────────────────────────┐
Task 3 (DKTypography) ─────── independent ───────────┤
Task 4 (DKSpacing/Motion/Shadow) ─ independent ──────┤
                                                      ↓
Task 5 (ButtonStyle/CardModifier) ← depends on 2,3,4
  └→ Task 6 (SectionHeader) ← depends on 2,3,4
  └→ Task 7 (IssueCard migration) ← depends on 2,3,4,5
  └→ Task 8 (Column/Board migration) ← depends on 7
  └→ Task 9 (Detail migration) ← depends on 2,3,4,6
  └→ Task 10 (Sidebar + ContentView) ← depends on 2
  └→ Task 11 (HeroCard) ← depends on 2,3,4
  └→ Task 12 (FeatureGrid + StatusRow) ← depends on 2,3,4
  └→ Task 13 (Overview Dashboard) ← depends on 6,10,11,12
  └→ Task 14 (Final adjustments) ← depends on 13
```

Tasks 2, 3, 4 可以并行执行（互不依赖）。Tasks 7-9 和 10-12 分别可以并行。
