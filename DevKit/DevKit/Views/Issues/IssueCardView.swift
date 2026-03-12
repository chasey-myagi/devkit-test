import SwiftUI
import SwiftData

struct IssueCardView: View {
    let issue: CachedIssue
    @Query private var cachedPRs: [CachedPR]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    init(issue: CachedIssue) {
        self.issue = issue
        let workspace = issue.workspaceName
        _cachedPRs = Query(filter: #Predicate<CachedPR> { $0.workspaceName == workspace })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            HStack {
                Text("#\(issue.number)")
                    .font(DKTypography.issueNumber())
                    .foregroundStyle(DKColor.Foreground.secondary)
                Spacer()
                if let severity = issue.severity {
                    severityBadge(severity)
                }
            }

            Text(issue.title)
                .dkTextStyle(.cardTitle)
                .foregroundStyle(DKColor.Foreground.primary)
                .lineLimit(2)

            HStack {
                if let customer = issue.customer {
                    Label(customer, systemImage: "building.2")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Foreground.secondary)
                }
                Spacer()
                Text(issue.updatedAt, style: .relative)
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.tertiary)
            }

            // Linked PR status — preserved from original
            if !issue.linkedPRNumbers.isEmpty {
                linkedPRStatusRow
            }
        }
        .padding(DKSpacing.md)
        .background(DKColor.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
        .dkShadow(isHovered ? DKShadow.md : DKShadow.sm)
        .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1.0)
        .animation(reduceMotion ? nil : DKMotion.Ease.hover, value: isHovered)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var linkedPRStatusRow: some View {
        let linkedPRs = cachedPRs.filter { issue.linkedPRNumbers.contains($0.number) }
        if !linkedPRs.isEmpty {
            HStack(spacing: DKSpacing.sm) {
                Image(systemName: "arrow.triangle.pull")
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.secondary)
                ForEach(linkedPRs, id: \.number) { pr in
                    HStack(spacing: DKSpacing.xxs) {
                        prStatusIcon(for: pr)
                        Text("#\(pr.number)")
                            .font(DKTypography.captionSmall())
                    }
                    .foregroundStyle(prStatusColor(for: pr))
                }
                Spacer()
            }
        }
    }

    private func prStatusIcon(for pr: CachedPR) -> Image {
        switch pr.reviewState {
        case "APPROVED":
            Image(systemName: "checkmark.circle.fill")
        case "CHANGES_REQUESTED":
            Image(systemName: "exclamationmark.triangle.fill")
        default:
            Image(systemName: "clock.fill")
        }
    }

    private func prStatusColor(for pr: CachedPR) -> Color {
        switch pr.reviewState {
        case "APPROVED": DKColor.Accent.positive
        case "CHANGES_REQUESTED": DKColor.Accent.warning
        default: Color.secondary
        }
    }

    private func severityBadge(_ severity: String) -> some View {
        Text(severity)
            .font(DKTypography.captionSmall())
            .padding(.horizontal, DKSpacing.xs)
            .padding(.vertical, DKSpacing.xxs)
            .background(DKColor.Accent.tintBackground(DKColor.Accent.severity(severity), colorScheme: colorScheme))
            .foregroundStyle(DKColor.Accent.severity(severity))
            .clipShape(Capsule())
    }
}
