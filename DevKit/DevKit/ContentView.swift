import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var workspaces: [Workspace]
    @State private var selectedTab: SidebarView.SidebarTab = .issues
    @State private var selectedWorkspaceName: String?

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
            if let ws = selectedWorkspace {
                switch selectedTab {
                case .issues:
                    Text("Issue Board — coming next")
                case .prs:
                    Text("PR Board — Phase 2")
                }
            } else {
                ContentUnavailableView(
                    "No Workspace Selected",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Add a workspace in Settings or select one from the sidebar.")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
