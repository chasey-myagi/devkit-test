import SwiftUI

struct PRColumnView: View {
    let title: String
    let prs: [CachedPR]
    let repoFullName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
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
                LazyVStack(spacing: DKSpacing.sm) {
                    ForEach(prs) { pr in
                        NavigationLink(value: pr) {
                            PRCardView(pr: pr)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(DKSpacing.sm)
            }
        }
        .background(DKColor.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
    }
}
