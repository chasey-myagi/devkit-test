// DevKit/DevKit/Views/Components/DKEmptyStateView.swift
import SwiftUI

struct DKEmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String?
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
