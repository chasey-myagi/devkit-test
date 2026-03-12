import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workspaces: [Workspace]
    @State private var selectedTab: SidebarView.SidebarTab = .issues
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
                    case .issues:
                        IssueBoardView(workspace: ws, viewModel: boardViewModel)
                    case .prs:
                        PRBoardView(workspace: ws, viewModel: prBoardViewModel)
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
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: selectedWorkspaceName) { _, newName in
            monitor?.stopPolling()
            guard let ws = workspaces.first(where: { $0.name == newName }) else {
                monitor = nil
                boardViewModel = nil
                prBoardViewModel = nil
                return
            }
            let container = modelContext.container
            let newMonitor = GitHubMonitor(ghClient: ghClient, modelContainer: container)
            let newVM = IssueBoardViewModel(ghClient: ghClient, monitor: newMonitor, modelContainer: container)
            monitor = newMonitor
            boardViewModel = newVM
            prBoardViewModel = PRBoardViewModel(ghClient: ghClient, modelContainer: container)
            newMonitor.startPolling(
                repo: ws.repoFullName,
                workspaceName: ws.name,
                interval: TimeInterval(ws.pollingIntervalSeconds)
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshIssues)) { _ in
            guard let ws = selectedWorkspace else { return }
            Task {
                await boardViewModel?.refresh(workspace: ws)
                await prBoardViewModel?.refresh(workspace: ws)
            }
        }
    }
}
