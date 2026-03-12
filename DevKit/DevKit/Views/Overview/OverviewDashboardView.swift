import SwiftUI
import SwiftData

struct OverviewDashboardView: View {
    let workspace: Workspace
    var onNavigateToBoard: (() -> Void)?
    @Query private var allIssues: [CachedIssue]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    init(workspace: Workspace, onNavigateToBoard: (() -> Void)? = nil) {
        self.workspace = workspace
        self.onNavigateToBoard = onNavigateToBoard
        let name = workspace.name
        _allIssues = Query(
            filter: #Predicate<CachedIssue> { $0.workspaceName == name },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    private var openIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus != "Done" }
    }
    private var criticalIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s-1" }
    }
    private var warningIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s0" }
    }
    private var healthyIssues: [CachedIssue] {
        openIssues.filter { $0.severity == "s2" || $0.severity == nil }
    }
    private var recentActivity: [CachedIssue] {
        Array(allIssues.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Card
                HeroCardView(
                    workspaceName: workspace.name,
                    openCount: openIssues.count,
                    attentionCount: criticalIssues.count + warningIssues.count,
                    onTapBoard: { onNavigateToBoard?() }
                )
                .padding(.bottom, DKSpacing.xxl)

                // Feature Grid
                DKSectionHeader(title: "Overview", icon: "square.grid.2x2")
                    .padding(.bottom, DKSpacing.md)

                HStack(spacing: DKSpacing.md) {
                    FeatureGridCardView(
                        title: "\(criticalIssues.count) critical issues",
                        subtitle: "Needs attention",
                        backgroundColor: DKColor.Accent.critical.opacity(0.12),
                        onTap: { onNavigateToBoard?() }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.18), value: appeared)

                    FeatureGridCardView(
                        title: "\(warningIssues.count) warnings",
                        subtitle: "Monitor closely",
                        backgroundColor: DKColor.Accent.warning.opacity(0.12),
                        onTap: { onNavigateToBoard?() }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.26), value: appeared)

                    FeatureGridCardView(
                        title: "\(healthyIssues.count) healthy",
                        subtitle: "On track",
                        backgroundColor: DKColor.Accent.positive.opacity(0.12),
                        onTap: { onNavigateToBoard?() }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(reduceMotion ? nil : DKMotion.Ease.appear.delay(0.34), value: appeared)
                }
                .padding(.bottom, DKSpacing.xxl)

                // Recent Activity
                DKSectionHeader(title: "Recent Activity", icon: "clock")
                    .padding(.bottom, DKSpacing.md)

                if recentActivity.isEmpty {
                    DKEmptyStateView(
                        icon: "tray",
                        title: "No activity yet",
                        subtitle: "Issues will appear here once synced"
                    )
                } else {
                    let lastID = recentActivity.last?.id
                    VStack(spacing: 0) {
                        ForEach(recentActivity) { issue in
                            StatusListRowView(
                                icon: statusIcon(for: issue),
                                iconColor: DKColor.Accent.severity(issue.severity ?? ""),
                                title: issue.title,
                                subtitle: "#\(issue.number) · \(issue.updatedAt.formatted(.relative(presentation: .named)))"
                            )
                            if issue.id != lastID {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .background(DKColor.Surface.card)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                    .dkShadow(DKShadow.sm)
                }
            }
            .padding(DKSpacing.xl)
        }
        .background(DKColor.Surface.primary)
        .onAppear { appeared = true }
    }

    private func statusIcon(for issue: CachedIssue) -> String {
        switch issue.severity {
        case "s-1": "exclamationmark.triangle.fill"
        case "s0": "exclamationmark.circle.fill"
        default: "circle.fill"
        }
    }
}
