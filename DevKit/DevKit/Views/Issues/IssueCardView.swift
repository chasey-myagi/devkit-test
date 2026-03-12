import SwiftUI
import SwiftData

struct IssueCardView: View {
    let issue: CachedIssue
    @Query private var cachedPRs: [CachedPR]

    init(issue: CachedIssue) {
        self.issue = issue
        let workspace = issue.workspaceName
        _cachedPRs = Query(filter: #Predicate<CachedPR> { $0.workspaceName == workspace })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(issue.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let severity = issue.severity {
                    Text(severity)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(severityColor(severity).opacity(0.2))
                        .foregroundStyle(severityColor(severity))
                        .clipShape(Capsule())
                }
            }

            Text(issue.title)
                .font(.subheadline)
                .lineLimit(2)

            HStack {
                if let customer = issue.customer {
                    Label(customer, systemImage: "building.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(issue.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Linked PR status
            if !issue.linkedPRNumbers.isEmpty {
                linkedPRStatusRow
            }
        }
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    @ViewBuilder
    private var linkedPRStatusRow: some View {
        let linkedPRs = cachedPRs.filter { issue.linkedPRNumbers.contains($0.number) }
        if !linkedPRs.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.pull")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(linkedPRs, id: \.number) { pr in
                    HStack(spacing: 2) {
                        prStatusIcon(for: pr)
                        Text("#\(pr.number)")
                            .font(.caption2)
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
            return Image(systemName: "checkmark.circle.fill")
        case "CHANGES_REQUESTED":
            return Image(systemName: "exclamationmark.triangle.fill")
        default:
            return Image(systemName: "clock.fill")
        }
    }

    private func prStatusColor(for pr: CachedPR) -> Color {
        switch pr.reviewState {
        case "APPROVED": return .green
        case "CHANGES_REQUESTED": return .orange
        default: return .secondary
        }
    }

    private func severityColor(_ s: String) -> Color {
        switch s {
        case "s-1": return .red
        case "s0": return .orange
        case "s1": return .yellow
        case "s2": return .green
        default: return .secondary
        }
    }
}
