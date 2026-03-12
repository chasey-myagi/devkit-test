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
                    let manager = WorkspaceManager(modelContainer: modelContext.container)
                    for i in indexSet {
                        do {
                            try manager.delete(name: workspaces[i].name)
                        } catch {
                            addError = error.localizedDescription
                        }
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
        }
        .padding(DKSpacing.lg)
    }

    private var addWorkspaceSheet: some View {
        VStack(spacing: DKSpacing.md) {
            Text("Add Workspace")
                .font(DKTypography.pageTitle())
                .foregroundStyle(DKColor.Foreground.primary)
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
                .buttonStyle(DKSecondaryButtonStyle())
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
        .frame(width: 400)
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
