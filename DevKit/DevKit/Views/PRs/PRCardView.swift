import SwiftUI

struct PRCardView: View {
    let pr: CachedPR
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: DKSpacing.sm) {
            // PR number + review state
            HStack {
                Text("#\(pr.number)")
                    .font(DKTypography.issueNumber())
                    .foregroundStyle(DKColor.Foreground.secondary)
                Spacer()
                reviewBadge
            }

            // Title
            Text(pr.title)
                .dkTextStyle(.cardTitle)
                .foregroundStyle(DKColor.Foreground.primary)
                .lineLimit(2)

            // Diff stats + CI status
            HStack(spacing: DKSpacing.sm) {
                // Diff stats
                HStack(spacing: DKSpacing.xs) {
                    Text("+\(pr.additions)")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Accent.positive)
                    Text("-\(pr.deletions)")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Accent.critical)
                }

                // Linked issues
                if !pr.linkedIssueNumbers.isEmpty {
                    let issueText = pr.linkedIssueNumbers.map { "#\($0)" }.joined(separator: ", ")
                    Label(issueText, systemImage: "link")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Foreground.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // CI status icon
                ciStatusIcon

                // Updated time
                Text(pr.updatedAt, style: .relative)
                    .font(DKTypography.captionSmall())
                    .foregroundStyle(DKColor.Foreground.tertiary)
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

    private var reviewBadge: some View {
        Text(reviewLabel)
            .font(DKTypography.captionSmall())
            .padding(.horizontal, DKSpacing.xs)
            .padding(.vertical, DKSpacing.xxs)
            .background(DKColor.Accent.tintBackground(reviewColor, colorScheme: colorScheme))
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
        case "APPROVED": return DKColor.Accent.positive
        case "CHANGES_REQUESTED": return DKColor.Accent.warning
        default: return Color.secondary
        }
    }

    private var ciStatusIcon: some View {
        Group {
            switch pr.checksStatus {
            case "SUCCESS":
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DKColor.Accent.positive)
            case "FAILURE":
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(DKColor.Accent.critical)
            default:
                Image(systemName: "clock.circle")
                    .foregroundStyle(DKColor.Foreground.secondary)
            }
        }
        .font(DKTypography.caption())
    }
}
