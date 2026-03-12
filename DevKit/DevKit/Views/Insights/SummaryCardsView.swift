import SwiftUI

/// 摘要统计卡片网格
struct SummaryCardsView: View {
    var summary: InsightSummary

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SummaryCard(
                title: "Total Issues",
                value: "\(summary.totalIssues)",
                subtitle: "\(summary.openIssues) open, \(summary.closedIssues) done",
                icon: "exclamationmark.circle",
                color: .blue
            )

            SummaryCard(
                title: "Total PRs",
                value: "\(summary.totalPRs)",
                subtitle: "\(summary.openPRs) open, \(summary.mergedPRs) ready",
                icon: "arrow.triangle.pull",
                color: .purple
            )

            SummaryCard(
                title: "Avg Issue Age",
                value: String(format: "%.1f d", summary.avgIssueAge),
                subtitle: "days since last update",
                icon: "clock",
                color: .orange
            )

            SummaryCard(
                title: "Completion Rate",
                value: String(format: "%.0f%%", summary.issueCompletionRate * 100),
                subtitle: "issues marked done",
                icon: "checkmark.circle",
                color: .green
            )
        }
    }
}

/// 单个摘要卡片
struct SummaryCard: View {
    var title: String
    var value: String
    var subtitle: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
