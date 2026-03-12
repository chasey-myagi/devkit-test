// DevKit/DevKit/DesignSystem/DKButtonStyle.swift
import SwiftUI

struct DKScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DKMotion.Spring.stiff, value: configuration.isPressed)
    }
}

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

struct DKIconCircleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    var size: CGFloat = 40

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
