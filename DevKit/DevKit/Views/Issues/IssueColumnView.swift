import SwiftUI
import SwiftData

struct IssueColumnView: View {
    let title: String
    let status: String
    let issues: [CachedIssue]
    let allIssues: [CachedIssue]
    let onStatusChange: (CachedIssue, String) -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(DKTypography.bodyMedium())
                    .foregroundStyle(DKColor.Foreground.primary)
                Spacer()
                Text("\(issues.count)")
                    .font(DKTypography.caption())
                    .contentTransition(.numericText(value: Double(issues.count)))
                    .animation(DKMotion.Spring.default, value: issues.count)
                    .padding(.horizontal, DKSpacing.sm)
                    .padding(.vertical, DKSpacing.xxs)
                    .background(DKColor.Surface.tertiary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DKSpacing.md)
            .padding(.vertical, DKSpacing.sm)

            Divider()

            ScrollView {
                LazyVStack(spacing: DKSpacing.sm) {
                    ForEach(issues) { issue in
                        NavigationLink(value: issue) {
                            IssueCardView(issue: issue)
                        }
                        .buttonStyle(.plain)
                        .draggable(String(issue.number))
                    }
                }
                .padding(DKSpacing.sm)
            }
        }
        .background(isDropTargeted ? DKColor.Surface.tertiary : DKColor.Surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DKRadius.xl)
                .stroke(DKColor.Accent.brand.opacity(0.5), lineWidth: 2)
                .opacity(isDropTargeted ? 1 : 0)
        )
        .animation(DKMotion.Ease.appear, value: isDropTargeted)
        .dropDestination(for: String.self) { items, _ in
            guard let numberStr = items.first,
                  let number = Int(numberStr),
                  let issue = allIssues.first(where: { $0.number == number })
            else { return false }
            onStatusChange(issue, status)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }
}
