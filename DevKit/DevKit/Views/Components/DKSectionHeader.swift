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
