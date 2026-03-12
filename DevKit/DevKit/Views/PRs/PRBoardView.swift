import SwiftUI
import SwiftData

struct PRBoardView: View {
    let workspace: Workspace
    @Query private var allPRs: [CachedPR]
    var viewModel: PRBoardViewModel?

    init(workspace: Workspace, viewModel: PRBoardViewModel? = nil) {
        self.workspace = workspace
        self.viewModel = viewModel
        let name = workspace.name
        _allPRs = Query(
            filter: #Predicate<CachedPR> { $0.workspaceName == name },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    private var draftPRs: [CachedPR] {
        allPRs.filter { $0.boardColumn == "Draft" }
    }
    private var inReviewPRs: [CachedPR] {
        allPRs.filter { $0.boardColumn == "In Review" }
    }
    private var needFixPRs: [CachedPR] {
        allPRs.filter { $0.boardColumn == "Need Fix" }
    }
    private var readyPRs: [CachedPR] {
        allPRs.filter { $0.boardColumn == "Ready" }
    }

    var body: some View {
        HStack(spacing: 12) {
            PRColumnView(title: "Draft", prs: draftPRs, repoFullName: workspace.repoFullName)
            PRColumnView(title: "In Review", prs: inReviewPRs, repoFullName: workspace.repoFullName)
            PRColumnView(title: "Need Fix", prs: needFixPRs, repoFullName: workspace.repoFullName)
            PRColumnView(title: "Ready", prs: readyPRs, repoFullName: workspace.repoFullName)
        }
        .padding()
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
                ProgressView()
            }
        }
        .navigationDestination(for: CachedPR.self) { pr in
            PRDetailView(pr: pr, repoFullName: workspace.repoFullName)
        }
    }
}
