import SwiftUI

struct PRCardView: View {
    let pr: CachedPR

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // PR number + review state
            HStack {
                Text("#\(pr.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                reviewBadge
            }

            // Title
            Text(pr.title)
                .font(.subheadline)
                .lineLimit(2)

            // Diff stats + CI status
            HStack(spacing: 8) {
                // Diff stats
                HStack(spacing: 4) {
                    Text("+\(pr.additions)")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("-\(pr.deletions)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                // Linked issues
                if !pr.linkedIssueNumbers.isEmpty {
                    let issueText = pr.linkedIssueNumbers.map { "#\($0)" }.joined(separator: ", ")
                    Label(issueText, systemImage: "link")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // CI status icon
                ciStatusIcon

                // Updated time
                Text(pr.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    private var reviewBadge: some View {
        Text(reviewLabel)
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(reviewColor.opacity(0.2))
            .foregroundStyle(reviewColor)
            .clipShape(Capsule())
    }

    private var reviewLabel: String {
        switch pr.reviewState {
        case "APPROVED": return "Approved"
        case "CHANGES_REQUESTED": return "Changes"
        default: return "Pending"
        }
    }

    private var reviewColor: Color {
        switch pr.reviewState {
        case "APPROVED": return .green
        case "CHANGES_REQUESTED": return .orange
        default: return .secondary
        }
    }

    private var ciStatusIcon: some View {
        Group {
            switch pr.checksStatus {
            case "SUCCESS":
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case "FAILURE":
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            default:
                Image(systemName: "clock.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}
