// DevKit/DevKit/DesignSystem/DKCardModifier.swift
import SwiftUI

struct DKCardModifier: ViewModifier {
    var cornerRadius: CGFloat = DKRadius.lg
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(DKColor.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .dkShadow(isHovered
                ? (colorScheme == .dark ? DKShadow.sm : DKShadow.md)
                : (colorScheme == .dark ? DKShadow.none : DKShadow.sm))
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
