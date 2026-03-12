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
    @State private var addError: String?
    @State private var workspaceToDelete: Workspace?
    private let ghClient = GitHubCLIClient()

    var body: some View {
        TabView {
            workspaceSettings
                .tabItem { Label("Workspaces", systemImage: "folder") }

            githubSettings
                .tabItem { Label("GitHub", systemImage: "globe") }

            agentSettings
                .tabItem { Label("Agent", systemImage: "cpu") }
        }
        .frame(width: 500, height: 550)
    }

    // MARK: - Workspace Settings

    private var workspaceSettings: some View {
        VStack(alignment: .leading, spacing: DKSpacing.md) {
            List {
                ForEach(workspaces) { ws in
                    VStack(alignment: .leading, spacing: DKSpacing.xs) {
                        Text(ws.name)
                            .font(DKTypography.bodyMedium())
                            .foregroundStyle(DKColor.Foreground.primary)
                        Text(ws.repoFullName)
                            .font(DKTypography.caption())
                            .foregroundStyle(DKColor.Foreground.secondary)
                        Text(ws.localPath)
                            .font(DKTypography.captionSmall())
                            .foregroundStyle(DKColor.Foreground.tertiary)
                    }
                }
                .onDelete { indexSet in
                    if let i = indexSet.first {
                        workspaceToDelete = workspaces[i]
                    }
                }
            }

            Button("Add Workspace...") {
                showAddSheet = true
            }
            .buttonStyle(DKPrimaryButtonStyle())
            .sheet(isPresented: $showAddSheet) {
                addWorkspaceSheet
            }
            .alert("Delete Workspace?", isPresented: Binding(
                get: { workspaceToDelete != nil },
                set: { if !$0 { workspaceToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { workspaceToDelete = nil }
                Button("Delete", role: .destructive) {
                    guard let ws = workspaceToDelete else { return }
                    let manager = WorkspaceManager(modelContainer: modelContext.container)
                    do {
                        try manager.delete(name: ws.name)
                    } catch {
                        addError = error.localizedDescription
                    }
                    workspaceToDelete = nil
                }
            } message: {
                Text("This will remove \"\(workspaceToDelete?.name ?? "")\" and all cached data. This cannot be undone.")
            }
        }
        .padding(DKSpacing.lg)
    }

    private var addWorkspaceSheet: some View {
        VStack(alignment: .leading, spacing: DKSpacing.lg) {
            Text("Add Workspace")
                .font(DKTypography.pageTitle())
                .foregroundStyle(DKColor.Foreground.primary)

            settingsField("Name", text: $newWorkspaceName, prompt: "my-project")
            settingsField("Repo", text: $newRepoFullName, prompt: "owner/repo-name")

            VStack(alignment: .leading, spacing: DKSpacing.xs) {
                Text("Local Path")
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Foreground.secondary)
                HStack(spacing: DKSpacing.sm) {
                    TextField("/Users/you/projects/repo", text: $newLocalPath)
                        .textFieldStyle(.plain)
                        .font(DKTypography.body())
                        .padding(.horizontal, DKSpacing.md)
                        .frame(height: 36)
                        .background(DKColor.Surface.tertiary.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            newLocalPath = url.path
                        }
                    }
                    .buttonStyle(DKSecondaryButtonStyle())
                }
            }

            if let addError {
                Text(addError)
                    .font(DKTypography.caption())
                    .foregroundStyle(DKColor.Accent.critical)
            }

            HStack {
                Button("Cancel") {
                    showAddSheet = false
                    addError = nil
                }
                .buttonStyle(DKGhostButtonStyle())
                Spacer()
                Button("Add") {
                    let manager = WorkspaceManager(modelContainer: modelContext.container)
                    do {
                        try manager.add(
                            name: newWorkspaceName,
                            repoFullName: newRepoFullName,
                            localPath: newLocalPath
                        )
                        newWorkspaceName = ""
                        newRepoFullName = ""
                        newLocalPath = ""
                        showAddSheet = false
                        addError = nil
                    } catch {
                        addError = error.localizedDescription
                    }
                }
                .buttonStyle(DKPrimaryButtonStyle())
                .disabled(newWorkspaceName.isEmpty || newRepoFullName.isEmpty || newLocalPath.isEmpty)
            }
        }
        .padding(DKSpacing.xl)
        .frame(width: 420)
    }

    private func settingsField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: DKSpacing.xs) {
            Text(label)
                .font(DKTypography.caption())
                .foregroundStyle(DKColor.Foreground.secondary)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(DKTypography.body())
                .padding(.horizontal, DKSpacing.md)
                .frame(height: 36)
                .background(DKColor.Surface.tertiary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.sm))
        }
    }

    // MARK: - GitHub Settings

    private var githubSettings: some View {
        VStack(alignment: .leading, spacing: DKSpacing.md) {
            DKSectionHeader(title: "GitHub CLI Status", icon: "globe")
            VStack(alignment: .leading, spacing: DKSpacing.md) {
                Text(ghAuthStatus)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DKColor.Foreground.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Refresh") {
                    Task {
                        do {
                            ghAuthStatus = try await ghClient.checkAuthStatus()
                        } catch {
                            ghAuthStatus = "Error: \(error.localizedDescription)"
                        }
                    }
                }
                .buttonStyle(DKSecondaryButtonStyle())
            }
            .padding(DKSpacing.lg)
            .background(DKColor.Surface.card)
            .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
            .dkShadow(DKShadow.sm)
        }
        .padding(DKSpacing.lg)
        .task {
            do {
                ghAuthStatus = try await ghClient.checkAuthStatus()
            } catch {
                ghAuthStatus = "Not authenticated. Run: gh auth login"
            }
        }
    }

    // MARK: - Agent Settings

    private var agentSettings: some View {
        VStack(alignment: .leading, spacing: DKSpacing.md) {
            if let ws = workspaces.first(where: { $0.isActive }) ?? workspaces.first {
                DKSectionHeader(title: "Polling", icon: "clock")
                VStack(spacing: DKSpacing.sm) {
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
                .padding(DKSpacing.lg)
                .background(DKColor.Surface.card)
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                .dkShadow(DKShadow.sm)

                DKSectionHeader(title: "Concurrency", icon: "cpu")
                VStack(spacing: DKSpacing.sm) {
                    Stepper("Max parallel agents: \(ws.maxConcurrency)",
                            value: Binding(
                                get: { ws.maxConcurrency },
                                set: { ws.maxConcurrency = $0 }
                            ),
                            in: 1...5)
                        .font(DKTypography.body())
                        .foregroundStyle(DKColor.Foreground.primary)
                }
                .padding(DKSpacing.lg)
                .background(DKColor.Surface.card)
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                .dkShadow(DKShadow.sm)

                DKSectionHeader(title: "Prompt Template", icon: "text.bubble")
                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    Text("支持占位符：{{number}}, {{title}}, {{body}}, {{labels}}, {{repo}}, {{attachments}}")
                        .font(DKTypography.captionSmall())
                        .foregroundStyle(DKColor.Foreground.tertiary)
                    TextEditor(text: Binding(
                        get: { ws.agentPromptTemplate },
                        set: { ws.agentPromptTemplate = $0 }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: DKRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DKRadius.lg)
                            .stroke(DKColor.Surface.tertiary, lineWidth: 1)
                    )
                }
                .padding(DKSpacing.lg)
                .background(DKColor.Surface.card)
                .clipShape(RoundedRectangle(cornerRadius: DKRadius.xl))
                .dkShadow(DKShadow.sm)
            } else {
                DKEmptyStateView(
                    icon: "folder",
                    title: "No Workspace",
                    subtitle: "Add a workspace first."
                )
            }
        }
        .padding(DKSpacing.lg)
    }
}
