import SwiftUI
import SwiftData

struct IssueBoardView: View {
    let workspace: Workspace
    @Query private var allIssues: [CachedIssue]
    @State private var viewModel: IssueBoardViewModel?

    init(workspace: Workspace) {
        self.workspace = workspace
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

    var body: some View {
        HStack(spacing: 12) {
            IssueColumnView(title: "To Do", status: "To Do", issues: todoIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
            IssueColumnView(title: "In Progress", status: "In Progress", issues: inProgressIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
            IssueColumnView(title: "Done", status: "Done", issues: doneIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel?.refresh(workspace: workspace) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .overlay {
            if viewModel?.isLoading == true {
                ProgressView()
            }
        }
        .navigationDestination(for: CachedIssue.self) { issue in
            IssueDetailView(issue: issue, repoFullName: workspace.repoFullName)
        }
    }
}
