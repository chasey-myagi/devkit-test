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
