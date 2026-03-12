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
