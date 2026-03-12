import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query private var workspaces: [Workspace]
    @Binding var selectedWorkspaceName: String?
    @Binding var selectedTab: SidebarTab

    /// Resolved workspace from name binding
    var selectedWorkspace: Workspace? {
        workspaces.first { $0.name == selectedWorkspaceName }
    }

    enum SidebarTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case issues = "Issues"
        case prs = "Pull Requests"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .issues: return "exclamationmark.circle"
            case .prs: return "arrow.triangle.pull"
            }
        }
    }

    var body: some View {
        List(selection: $selectedTab) {
            Section("Workspace") {
                Picker("Workspace", selection: $selectedWorkspaceName) {
                    Text("None").tag(String?.none)
                    ForEach(workspaces) { ws in
                        Text(ws.name).tag(String?.some(ws.name))
                    }
                }
                .labelsHidden()
            }

            Section("Navigation") {
                ForEach(SidebarTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("DevKit")
    }
}
