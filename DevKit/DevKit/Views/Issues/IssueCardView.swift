import SwiftUI

struct IssueCardView: View {
    let issue: CachedIssue

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
        }
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
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
