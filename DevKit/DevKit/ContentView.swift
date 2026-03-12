import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workspaces: [Workspace]
    @State private var selectedTab: SidebarView.SidebarTab = .overview
    @State private var selectedWorkspaceName: String?
    private let ghClient = GitHubCLIClient()
    @State private var monitor: GitHubMonitor?
    @State private var boardViewModel: IssueBoardViewModel?
    @State private var prBoardViewModel: PRBoardViewModel?

    /// Resolved workspace object from name
    private var selectedWorkspace: Workspace? {
        workspaces.first { $0.name == selectedWorkspaceName }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedWorkspaceName: $selectedWorkspaceName,
                selectedTab: $selectedTab
            )
        } detail: {
            NavigationStack {
                if let ws = selectedWorkspace {
                    switch selectedTab {
                    case .overview:
                        OverviewDashboardView(workspace: ws, onNavigateToBoard: { selectedTab = .issues })
                    case .issues:
                        IssueBoardView(workspace: ws, viewModel: boardViewModel)
                    case .prs:
                        PRBoardView(workspace: ws, viewModel: prBoardViewModel)
                            .task(id: ws.name) {
                                // I-6: PR 首次切换时自动加载
                                await prBoardViewModel?.refresh(workspace: ws)
                            }
                    }
                } else {
                    ContentUnavailableView(
                        "No Workspace Selected",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Add a workspace in Settings or select one from the sidebar.")
                    )
                }
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .background(DKColor.Surface.primary)
        .onChange(of: selectedWorkspaceName) { _, newName in
            setupWorkspace(name: newName)
        }
        // I-4: 轮询间隔修改后立即生效
        .onChange(of: selectedWorkspace?.pollingIntervalSeconds) { _, newInterval in
            guard let ws = selectedWorkspace, let interval = newInterval else { return }
            monitor?.stopPolling()
            startPolling(workspace: ws, interval: TimeInterval(interval))
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshIssues)) { _ in
            guard let ws = selectedWorkspace else { return }
            Task {
                await boardViewModel?.refresh(workspace: ws)
                await prBoardViewModel?.refresh(workspace: ws)
            }
        }
    }

    private func setupWorkspace(name: String?) {
        monitor?.stopPolling()
        guard let ws = workspaces.first(where: { $0.name == name }) else {
            monitor = nil
            boardViewModel = nil
            prBoardViewModel = nil
            return
        }
        let container = modelContext.container
        let newMonitor = GitHubMonitor(ghClient: ghClient, modelContainer: container)
        let newVM = IssueBoardViewModel(ghClient: ghClient, monitor: newMonitor, modelContainer: container)
        let newPRVM = PRBoardViewModel(ghClient: ghClient, modelContainer: container)
        monitor = newMonitor
        boardViewModel = newVM
        prBoardViewModel = newPRVM
        startPolling(workspace: ws, interval: TimeInterval(ws.pollingIntervalSeconds))
    }

    private func startPolling(workspace ws: Workspace, interval: TimeInterval) {
        monitor?.startPolling(
            repo: ws.repoFullName,
            workspaceName: ws.name,
            interval: interval
        ) { [weak prBoardViewModel] in
            // I-1: 每次 issue 轮询后也自动刷新 PR
            await prBoardViewModel?.refresh(workspace: ws)
        }
    }
}
