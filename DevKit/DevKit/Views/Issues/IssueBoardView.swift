import SwiftUI
import SwiftData

struct IssueBoardView: View {
    let workspace: Workspace
    @Query private var allIssues: [CachedIssue]
    var viewModel: IssueBoardViewModel?
    @State private var searchVM = SearchFilterViewModel()

    init(workspace: Workspace, viewModel: IssueBoardViewModel? = nil) {
        self.workspace = workspace
        self.viewModel = viewModel
        let name = workspace.name
        _allIssues = Query(
            filter: #Predicate<CachedIssue> { $0.workspaceName == name },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    private var todoIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "To Do" || $0.projectStatus == "Todo" }
    }
    private var inProgressIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "In Progress" }
    }
    private var doneIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "Done" }
    }

    /// 从 issue 集合中提取所有唯一的 label
    private var availableLabels: [String] {
        Array(Set(allIssues.flatMap(\.labels))).sorted()
    }

    /// 从 issue 集合中提取所有唯一的 assignee
    private var availableAssignees: [String] {
        Array(Set(allIssues.flatMap(\.assignees))).sorted()
    }

    /// 从 issue 集合中提取所有唯一的 milestone
    private var availableMilestones: [String] {
        Array(Set(allIssues.compactMap(\.milestone))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchFilterBar(
                viewModel: searchVM,
                availableLabels: availableLabels,
                availableAssignees: availableAssignees,
                availableMilestones: availableMilestones
            )

            HStack(spacing: DKSpacing.md) {
                IssueColumnView(title: "To Do", status: "To Do", issues: searchVM.filterIssues(todoIssues), allIssues: allIssues) { issue, newStatus in
                    Task {
                        await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                    }
                }
                IssueColumnView(title: "In Progress", status: "In Progress", issues: searchVM.filterIssues(inProgressIssues), allIssues: allIssues) { issue, newStatus in
                    Task {
                        await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                    }
                }
                IssueColumnView(title: "Done", status: "Done", issues: searchVM.filterIssues(doneIssues), allIssues: allIssues) { issue, newStatus in
                    Task {
                        await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                    }
                }
            }
            .padding(DKSpacing.lg)
        }
        .background(DKColor.Surface.primary)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel?.refresh(workspace: workspace) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .overlay {
            if viewModel?.isLoading == true {
                ZStack {
                    Color.black.opacity(0.05)
                    VStack(spacing: DKSpacing.sm) {
                        ProgressView()
                        Text("Refreshing issues...")
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)
                    }
                    .padding(DKSpacing.lg)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.md))
                }
            }
        }
        .navigationDestination(for: CachedIssue.self) { issue in
            IssueDetailView(issue: issue, repoFullName: workspace.repoFullName, localPath: workspace.localPath)
        }
    }
}
