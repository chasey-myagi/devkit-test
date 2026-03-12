import SwiftUI

struct FeatureGridCardView: View {
    let title: String
    let subtitle: String
    let backgroundColor: Color
    var onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .dkTextStyle(.cardTitle)
                .foregroundStyle(DKColor.Foreground.primary)
                .lineLimit(3)

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
        .overlay(
            LinearGradient(
                colors: [.clear, .black.opacity(0.12)],
                startPoint: .init(x: 0.5, y: 0.6),
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DKRadius.xl)
                .stroke(DKColor.Surface.secondary.opacity(0.5), lineWidth: 1)
        )
        .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
        .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTap() }
    }
}
