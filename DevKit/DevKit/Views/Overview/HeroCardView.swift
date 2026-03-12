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
                    .contentTransition(.numericText(value: Double(openCount)))
                    .animation(DKMotion.Spring.default, value: openCount)
                Text("\(attentionCount) need attention.")
                    .dkTextStyle(.heroTitle)
                    .foregroundStyle(DKColor.Foreground.primary)
                    .italic()
                    .opacity(0.8)
                    .contentTransition(.numericText(value: Double(attentionCount)))
                    .animation(DKMotion.Spring.default, value: attentionCount)
            }

            Spacer()

            // Bottom action bar
            HStack {
                Text("View Issue Board")
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
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("View issue board, \(openCount) open issues, \(attentionCount) need attention")
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
                Color(red: 0.14, green: 0.12, blue: 0.22),
                Color(red: 0.16, green: 0.15, blue: 0.20),
                Color(red: 0.18, green: 0.15, blue: 0.24),
                Color(red: 0.13, green: 0.12, blue: 0.20),
                DKColor.Surface.card,
                Color(red: 0.16, green: 0.14, blue: 0.21),
                Color(red: 0.12, green: 0.10, blue: 0.22),
                Color(red: 0.15, green: 0.14, blue: 0.18),
                Color(red: 0.17, green: 0.16, blue: 0.22),
            ]
            : [
                Color(red: 0.92, green: 0.90, blue: 0.98),
                Color(red: 0.95, green: 0.93, blue: 0.97),
                Color(red: 0.96, green: 0.94, blue: 0.98),
                Color(red: 0.91, green: 0.89, blue: 0.97),
                DKColor.Surface.card,
                Color(red: 0.95, green: 0.94, blue: 0.98),
                Color(red: 0.89, green: 0.86, blue: 0.97),
                Color(red: 0.94, green: 0.93, blue: 0.96),
                Color(red: 0.96, green: 0.95, blue: 0.97),
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
