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
    @State private var coordinator: AgentCoordinator?

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
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            .toolbar(removing: .title)
        } detail: {
            NavigationStack {
                if let ws = selectedWorkspace {
                    Group {
                        switch selectedTab {
                        case .overview:
                            OverviewDashboardView(workspace: ws, onNavigateToBoard: { selectedTab = .issues })
                                .transition(.opacity.combined(with: .offset(x: -20)))
                        case .issues:
                            IssueBoardView(workspace: ws, viewModel: boardViewModel)
                                .transition(.opacity.combined(with: .offset(x: 20)))
                        case .prs:
                            PRBoardView(workspace: ws, viewModel: prBoardViewModel)
                                .task(id: ws.name) {
                                    // I-6: PR 首次切换时自动加载
                                    await prBoardViewModel?.refresh(workspace: ws)
                                }
                                .transition(.opacity.combined(with: .offset(x: 20)))
                        case .agents:
                            AgentBoardView(workspace: ws, coordinator: coordinator)
                                .transition(.opacity.combined(with: .offset(x: 20)))
                        }
                    }
                    .animation(DKMotion.Spring.default, value: selectedTab)
                    .navigationDestination(for: UUID.self) { sessionID in
                        AgentSessionDetailView(sessionID: sessionID, coordinator: coordinator)
                    }
                } else {
                    WelcomeView { name, repo, path in
                        let manager = WorkspaceManager(modelContainer: modelContext.container)
                        do {
                            try manager.add(name: name, repoFullName: repo, localPath: path)
                            // Auto-select is handled by onChange(of: workspaces.count)
                        } catch {
                            // Error handled inside WelcomeView form
                        }
                    }
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
        .onAppear {
            // Auto-select first workspace if none selected
            if selectedWorkspaceName == nil, let first = workspaces.first {
                selectedWorkspaceName = first.name
            }
        }
        .onChange(of: workspaces.count) { _, _ in
            // When a workspace is added and none selected, auto-select it
            if selectedWorkspaceName == nil, let first = workspaces.first {
                selectedWorkspaceName = first.name
            }
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
        coordinator?.stop()
        guard let ws = workspaces.first(where: { $0.name == name }) else {
            monitor = nil
            boardViewModel = nil
            prBoardViewModel = nil
            coordinator = nil
            return
        }
        let container = modelContext.container
        let newMonitor = GitHubMonitor(ghClient: ghClient, modelContainer: container)
        let newCoordinator = AgentCoordinator(ghClient: ghClient)
        newCoordinator.setup(modelContainer: container, maxConcurrency: ws.maxConcurrency)
        let newVM = IssueBoardViewModel(ghClient: ghClient, monitor: newMonitor, modelContainer: container, coordinator: newCoordinator)
        let newPRVM = PRBoardViewModel(ghClient: ghClient, modelContainer: container)
        monitor = newMonitor
        boardViewModel = newVM
        prBoardViewModel = newPRVM
        coordinator = newCoordinator
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
