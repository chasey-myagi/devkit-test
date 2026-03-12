import SwiftUI

struct PRColumnView: View {
    let title: String
    let prs: [CachedPR]
    let repoFullName: String

    private var columnIcon: String {
        switch title {
        case "Draft": return "pencil.circle"
        case "In Review": return "eye.circle"
        case "Need Fix": return "exclamationmark.circle"
        default: return "checkmark.circle.fill"
        }
    }

    private var columnColor: Color {
        switch title {
        case "Draft": return DKColor.Foreground.tertiary
        case "In Review": return DKColor.Accent.brand
        case "Need Fix": return DKColor.Accent.warning
        default: return DKColor.Accent.positive
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: columnIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(columnColor)
                Text(title)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Text("\(prs.count)")
                    .font(DKTypography.caption())
                    .contentTransition(.numericText(value: Double(prs.count)))
                    .animation(DKMotion.Spring.default, value: prs.count)
                    .padding(.horizontal, DKSpacing.sm)
                    .padding(.vertical, DKSpacing.xxs)
                    .background(DKColor.Surface.tertiary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)

            Divider()

            // Cards
            ScrollView {
                if prs.isEmpty {
                    VStack(spacing: DKSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(DKColor.Foreground.tertiary)
                        Text("No items")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DKSpacing.xxxl)
                } else {
                    LazyVStack(spacing: DKSpacing.sm) {
                        ForEach(prs) { pr in
                            NavigationLink(value: pr) {
                                PRCardView(pr: pr)
                            }
                            .buttonStyle(DKCardPressStyle())
                        }
                    }
                    .padding(DKSpacing.sm)
                }
            }
        }
        .background(DKColor.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
    }
}
