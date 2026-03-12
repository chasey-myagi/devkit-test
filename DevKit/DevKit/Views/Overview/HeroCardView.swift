import SwiftUI

struct HeroCardView: View {
    let workspaceName: String
    let openCount: Int
    let attentionCount: Int
    var onTapBoard: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: DKSpacing.xl) {
            // Capsule tag
            Text(workspaceName)
                .font(DKTypography.captionSmall())
                .foregroundStyle(DKColor.Foreground.secondary)
                .padding(.horizontal, DKSpacing.md)
                .padding(.vertical, DKSpacing.xs)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            // Hero title (serif)
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

            // Bottom action bar
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
        .scaleEffect(isHovered && !reduceMotion ? 1.008 : 1.0)
        .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTapBoard() }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 16)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.97)
        .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.1), value: appeared)
        .onAppear { appeared = true }
    }

    @ViewBuilder
    private var heroGradient: some View {
        let colors: [Color] = colorScheme == .dark
            ? [
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
