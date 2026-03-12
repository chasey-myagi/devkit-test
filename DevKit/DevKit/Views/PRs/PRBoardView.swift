import SwiftUI
import SwiftData

struct PRBoardView: View {
    let workspace: Workspace
    @Query private var allPRs: [CachedPR]
    var viewModel: PRBoardViewModel?
    @State private var searchVM = SearchFilterViewModel()

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
        VStack(spacing: 0) {
            SearchFilterBar(viewModel: searchVM)

            HStack(spacing: DKSpacing.md) {
                PRColumnView(title: "Draft", prs: searchVM.filterPRs(draftPRs), repoFullName: workspace.repoFullName)
                PRColumnView(title: "In Review", prs: searchVM.filterPRs(inReviewPRs), repoFullName: workspace.repoFullName)
                PRColumnView(title: "Need Fix", prs: searchVM.filterPRs(needFixPRs), repoFullName: workspace.repoFullName)
                PRColumnView(title: "Ready", prs: searchVM.filterPRs(readyPRs), repoFullName: workspace.repoFullName)
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
                ProgressView()
            }
        }
        .navigationDestination(for: CachedPR.self) { pr in
            PRDetailView(pr: pr, repoFullName: workspace.repoFullName)
        }
    }
}
