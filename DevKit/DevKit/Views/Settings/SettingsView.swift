import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workspaces: [Workspace]

    @State private var newWorkspaceName = ""
    @State private var newRepoFullName = ""
    @State private var newLocalPath = ""
    @State private var ghAuthStatus = "Checking..."
    @State private var showAddSheet = false

    var body: some View {
        TabView {
            workspaceSettings
                .tabItem { Label("Workspaces", systemImage: "folder") }

            githubSettings
                .tabItem { Label("GitHub", systemImage: "globe") }

            agentSettings
                .tabItem { Label("Agent", systemImage: "cpu") }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - Workspace Settings

    private var workspaceSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach(workspaces) { ws in
                    VStack(alignment: .leading) {
                        Text(ws.name).font(.headline)
                        Text(ws.repoFullName).font(.caption).foregroundStyle(.secondary)
                        Text(ws.localPath).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        modelContext.delete(workspaces[i])
                    }
                }
            }

            Button("Add Workspace...") {
                showAddSheet = true
            }
            .sheet(isPresented: $showAddSheet) {
                addWorkspaceSheet
            }
        }
        .padding()
    }

    private var addWorkspaceSheet: some View {
        VStack(spacing: 12) {
            Text("Add Workspace").font(.headline)
            TextField("Name", text: $newWorkspaceName)
            TextField("Repo (owner/name)", text: $newRepoFullName)
            HStack {
                TextField("Local Path", text: $newLocalPath)
                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK, let url = panel.url {
                        newLocalPath = url.path
                    }
                }
            }
            HStack {
                Button("Cancel") { showAddSheet = false }
                Spacer()
                Button("Add") {
                    let ws = Workspace(
                        name: newWorkspaceName,
                        repoFullName: newRepoFullName,
                        localPath: newLocalPath
                    )
                    modelContext.insert(ws)
                    newWorkspaceName = ""
                    newRepoFullName = ""
                    newLocalPath = ""
                    showAddSheet = false
                }
                .disabled(newWorkspaceName.isEmpty || newRepoFullName.isEmpty || newLocalPath.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - GitHub Settings

    private var githubSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("GitHub CLI Status") {
                Text(ghAuthStatus)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Refresh") {
                    Task {
                        do {
                            let client = GitHubCLIClient()
                            ghAuthStatus = try await client.checkAuthStatus()
                        } catch {
                            ghAuthStatus = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            do {
                let client = GitHubCLIClient()
                ghAuthStatus = try await client.checkAuthStatus()
            } catch {
                ghAuthStatus = "Not authenticated. Run: gh auth login"
            }
        }
    }

    // MARK: - Agent Settings

    private var agentSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let ws = workspaces.first(where: { $0.isActive }) ?? workspaces.first {
                GroupBox("Polling") {
                    Picker("Interval", selection: Binding(
                        get: { ws.pollingIntervalSeconds },
                        set: { ws.pollingIntervalSeconds = $0 }
                    )) {
                        Text("5 min").tag(300)
                        Text("15 min").tag(900)
                        Text("30 min").tag(1800)
                        Text("60 min").tag(3600)
                    }
                }

                GroupBox("Concurrency") {
                    Stepper("Max parallel agents: \(ws.maxConcurrency)",
                            value: Binding(
                                get: { ws.maxConcurrency },
                                set: { ws.maxConcurrency = $0 }
                            ),
                            in: 1...5)
                }
            } else {
                ContentUnavailableView("No Workspace", systemImage: "folder",
                    description: Text("Add a workspace first."))
            }
        }
        .padding()
    }
}
