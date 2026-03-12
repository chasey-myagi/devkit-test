# DevKit Phase 1 Code Review Fixes

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all issues (C1-C3, I1-I8, M1/M3/M4/M6/M8) found during SwiftUI code review of DevKit Phase 1 MVP.

**Architecture:** Targeted fixes to existing files. No new architectural patterns introduced — just correcting existing code to follow SwiftUI best practices, fix threading bugs, and wire up unused code.

**Tech Stack:** Swift 6.0, SwiftUI, SwiftData, Swift Testing

**Spec:** Code review report in conversation context

---

## File Map

| File | Changes |
|------|---------|
| `DevKit/Services/ProcessRunner.swift` | C1: Wrap blocking calls in continuation on background queue |
| `DevKit/Services/GitHubCLIClient.swift` | C2: Use GraphQL variables instead of string interpolation |
| `DevKit/ContentView.swift` | C3: Wrap detail in NavigationStack; I8: Remove `@State` from ghClient |
| `DevKit/Services/GitHubMonitor.swift` | I1: Batch status resolution with TaskGroup; I3: Add `private(set)`; I7: Clean up stale issues |
| `DevKit/ViewModels/IssueBoardViewModel.swift` | I3: Add `private(set)` |
| `DevKit/ViewModels/IssueDetailViewModel.swift` | I5: Accept ProcessRunning via init |
| `DevKit/Views/Issues/IssueDetailView.swift` | I6: Use workspace localPath; M3: Use indexed ForEach; M6: Parse comment date |
| `DevKit/Views/Settings/SettingsView.swift` | I4: Use WorkspaceManager for CRUD |
| `DevKit/DevKitApp.swift` | I2: Move refresh to environment action pattern |
| `DevKit/Models/GitHubModels.swift` | M1: Remove redundant keyDecodingStrategy; M6: Add date parsing to GHComment |
| `DevKit/Views/Issues/IssueBoardView.swift` | M8: Pre-compute filtered lists |
| `DevKitTests/Services/GitHubMonitorTests.swift` | Add test for stale issue cleanup |

---

## Task 1: C1 — Fix ProcessRunner blocking main thread

**Files:**
- Modify: `DevKit/DevKit/Services/ProcessRunner.swift`

- [ ] **Step 1: Wrap blocking Process calls in background continuation**

```swift
struct ProcessRunner: ProcessRunning {
    func run(_ executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [executable] + arguments
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let outStr = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus != 0 {
                    continuation.resume(throwing: ProcessRunnerError.executionFailed(
                        terminationStatus: process.terminationStatus, stderr: errStr
                    ))
                } else {
                    continuation.resume(returning: outStr)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Run existing tests to verify no regression**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -scheme DevKit -destination 'platform=macOS' -quiet 2>&1 | tail -20`
Expected: All 22 tests pass

- [ ] **Step 3: Commit**

```
fix: wrap ProcessRunner in background continuation to prevent UI freeze
```

---

## Task 2: C2 — Fix GraphQL injection in GitHubCLIClient

**Files:**
- Modify: `DevKit/DevKit/Services/GitHubCLIClient.swift`

- [ ] **Step 1: Refactor `fetchProjectStatus` to use GraphQL variables**

Replace string interpolation of owner/name with `-F` variable flags. `gh api graphql -F owner=X -F name=Y -F number=N -f query='...'` where the query uses `$owner`, `$name`, `$number` as GraphQL variables.

```swift
func fetchProjectStatus(repo: String, issueNumber: Int) async throws -> String {
    let parts = repo.split(separator: "/")
    guard parts.count == 2 else { throw GitHubCLIError.invalidRepo(repo) }

    let query = """
    query($owner: String!, $name: String!, $number: Int!) {
        repository(owner: $owner, name: $name) {
            issue(number: $number) {
                projectItems(first: 10) {
                    nodes {
                        fieldValueByName(name: "Status") {
                            ... on ProjectV2ItemFieldSingleSelectValue {
                                name
                            }
                        }
                    }
                }
            }
        }
    }
    """
    let output = try await processRunner.run("gh", arguments: [
        "api", "graphql",
        "-F", "owner=\(parts[0])",
        "-F", "name=\(parts[1])",
        "-F", "number=\(issueNumber)",
        "-f", "query=\(query)"
    ])
    let response = try JSONDecoder.ghDecoder.decode(
        GHGraphQLProjectStatusResponse.self, from: Data(output.utf8)
    )
    let statusName = response.data.repository.issue.projectItems.nodes
        .first?.fieldValueByName?.name
    return statusName ?? "To Do"
}
```

- [ ] **Step 2: Refactor `updateProjectStatus` similarly**

Same pattern — use `-F` for owner, name, number in the lookup query. The mutation query uses IDs obtained from the lookup, which are safe (hex strings from GitHub).

```swift
func updateProjectStatus(repo: String, issueNumber: Int, newStatus: String) async throws {
    let parts = repo.split(separator: "/")
    guard parts.count == 2 else { throw GitHubCLIError.invalidRepo(repo) }

    let lookupQuery = """
    query($owner: String!, $name: String!, $number: Int!) {
        repository(owner: $owner, name: $name) {
            issue(number: $number) {
                projectItems(first: 10) {
                    nodes {
                        id
                        project {
                            id
                            field(name: "Status") {
                                ... on ProjectV2SingleSelectField {
                                    id
                                    options { id name }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    """
    let lookupOutput = try await processRunner.run("gh", arguments: [
        "api", "graphql",
        "-F", "owner=\(parts[0])",
        "-F", "name=\(parts[1])",
        "-F", "number=\(issueNumber)",
        "-f", "query=\(lookupQuery)"
    ])
    let lookupData = try JSONDecoder.ghDecoder.decode(
        GHGraphQLProjectLookupResponse.self, from: Data(lookupOutput.utf8)
    )
    guard let node = lookupData.data.repository.issue.projectItems.nodes.first else {
        throw GitHubCLIError.mutationFailed("Issue not in any project")
    }
    let itemId = node.id
    let projectId = node.project.id
    guard let fieldId = node.project.field?.id,
          let optionId = node.project.field?.options?.first(where: { $0.name == newStatus })?.id else {
        throw GitHubCLIError.mutationFailed("Status option '\(newStatus)' not found")
    }

    // Mutation uses IDs from lookup (safe hex strings), not user input
    let mutation = """
    mutation {
        updateProjectV2ItemFieldValue(input: {
            projectId: "\(projectId)"
            itemId: "\(itemId)"
            fieldId: "\(fieldId)"
            value: { singleSelectOptionId: "\(optionId)" }
        }) {
            projectV2Item { id }
        }
    }
    """
    _ = try await processRunner.run("gh", arguments: [
        "api", "graphql", "-f", "query=\(mutation)"
    ])
}
```

- [ ] **Step 3: Run existing tests**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -scheme DevKit -destination 'platform=macOS' -quiet 2>&1 | tail -20`
Expected: All tests pass (mock tests don't validate query content structure)

- [ ] **Step 4: Commit**

```
fix: use GraphQL variables to prevent injection in GitHubCLIClient
```

---

## Task 3: C3 + I8 — Fix navigation and state in ContentView

**Files:**
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: Wrap detail in NavigationStack and fix ghClient @State**

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workspaces: [Workspace]
    @State private var selectedTab: SidebarView.SidebarTab = .issues
    @State private var selectedWorkspaceName: String?
    private let ghClient = GitHubCLIClient()  // I8: not @State — stateless service
    @State private var monitor: GitHubMonitor?
    @State private var boardViewModel: IssueBoardViewModel?

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
            NavigationStack {  // C3: required for navigationDestination(for:)
                if let ws = selectedWorkspace {
                    switch selectedTab {
                    case .issues:
                        IssueBoardView(workspace: ws, viewModel: boardViewModel)
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
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: selectedWorkspaceName) { _, newName in
            monitor?.stopPolling()
            guard let ws = workspaces.first(where: { $0.name == newName }) else {
                monitor = nil
                boardViewModel = nil
                return
            }
            let container = modelContext.container
            let newMonitor = GitHubMonitor(ghClient: ghClient, modelContainer: container)
            let newVM = IssueBoardViewModel(ghClient: ghClient, monitor: newMonitor, modelContainer: container)
            monitor = newMonitor
            boardViewModel = newVM
            newMonitor.startPolling(
                repo: ws.repoFullName,
                workspaceName: ws.name,
                interval: TimeInterval(ws.pollingIntervalSeconds)
            )
        }
    }
}
```

- [ ] **Step 2: Run tests**

Expected: All tests pass

- [ ] **Step 3: Commit**

```
fix: add NavigationStack wrapper and remove @State from stateless service
```

---

## Task 4: I2 — Wire up Cmd+R refresh

**Files:**
- Modify: `DevKit/DevKit/DevKitApp.swift`
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: Add `.onReceive` for refresh notification in ContentView**

Add to ContentView body chain (after `.onChange`):

```swift
.onReceive(NotificationCenter.default.publisher(for: .refreshIssues)) { _ in
    guard let ws = selectedWorkspace else { return }
    Task {
        await boardViewModel?.refresh(workspace: ws)
    }
}
```

- [ ] **Step 2: Manual test — build and verify Cmd+R triggers refresh**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild build -scheme DevKit -destination 'platform=macOS' -quiet 2>&1 | tail -5`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```
fix: wire up Cmd+R refresh notification observer in ContentView
```

---

## Task 5: I3 — Add private(set) to observable properties

**Files:**
- Modify: `DevKit/DevKit/Services/GitHubMonitor.swift`
- Modify: `DevKit/DevKit/ViewModels/IssueBoardViewModel.swift`

- [ ] **Step 1: Restrict mutation in GitHubMonitor**

```swift
// Change from:
var isPolling = false
var lastPollDate: Date?
var lastError: String?
var consecutiveFailures = 0

// To:
private(set) var isPolling = false
private(set) var lastPollDate: Date?
private(set) var lastError: String?
private(set) var consecutiveFailures = 0
```

- [ ] **Step 2: Restrict mutation in IssueBoardViewModel**

```swift
// Change from:
var isLoading = false
var error: String?

// To:
private(set) var isLoading = false
private(set) var error: String?
```

- [ ] **Step 3: Run tests**

Expected: All tests pass (tests only read these properties, don't set them externally)

- [ ] **Step 4: Commit**

```
fix: add private(set) to observable state properties
```

---

## Task 6: I4 + M4 — Wire up WorkspaceManager in SettingsView

**Files:**
- Modify: `DevKit/DevKit/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Inject WorkspaceManager and use it for CRUD**

```swift
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

    // ... body unchanged ...

    // In workspaceSettings:
    // Replace .onDelete with:
    .onDelete { indexSet in
        for i in indexSet {
            let manager = WorkspaceManager(modelContainer: modelContext.container)
            try? manager.delete(name: workspaces[i].name)
        }
    }

    // In addWorkspaceSheet, replace Button("Add"):
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

    // In githubSettings, reuse single ghClient instance instead of creating new ones
```

- [ ] **Step 2: Run tests**

Expected: All tests pass

- [ ] **Step 3: Commit**

```
fix: use WorkspaceManager in SettingsView for validation
```

---

## Task 7: I5 — Fix DI in IssueDetailViewModel

**Files:**
- Modify: `DevKit/DevKit/ViewModels/IssueDetailViewModel.swift`
- Modify: `DevKit/DevKit/Views/Issues/IssueDetailView.swift`

- [ ] **Step 1: Accept ProcessRunning via init**

```swift
@MainActor
@Observable
final class IssueDetailViewModel {
    private let ghClient: GitHubCLIClient
    private let processRunner: ProcessRunning
    private(set) var isDownloading = false
    private(set) var downloadError: String?
    private(set) var comments: [GHComment] = []
    private(set) var isLoadingComments = false

    init(ghClient: GitHubCLIClient = GitHubCLIClient(), processRunner: ProcessRunning = ProcessRunner()) {
        self.ghClient = ghClient
        self.processRunner = processRunner
    }

    // ... loadComments unchanged ...

    func downloadAttachments(urls: [String], to directory: String) async {
        isDownloading = true
        defer { isDownloading = false }
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        } catch { /* ignore */ }
        for url in urls {
            do {
                let filename = URL(string: url)?.lastPathComponent ?? "attachment"
                let destPath = "\(directory)/\(filename)"
                _ = try await processRunner.run("curl", arguments: [
                    "-L", "-o", destPath, url
                ])
            } catch {
                downloadError = "Failed to download \(url): \(error.localizedDescription)"
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```
fix: inject ProcessRunning into IssueDetailViewModel for testability
```

---

## Task 8: I6 — Fix hardcoded download path + I7 — Stale issue cleanup

**Files:**
- Modify: `DevKit/DevKit/Views/Issues/IssueDetailView.swift` (I6)
- Modify: `DevKit/DevKit/Views/Issues/IssueBoardView.swift` (pass workspace)
- Modify: `DevKit/DevKit/Services/GitHubMonitor.swift` (I7)
- Modify: `DevKitTests/Services/GitHubMonitorTests.swift` (I7 test)

- [ ] **Step 1: I6 — Pass workspace to IssueDetailView and use its localPath**

In `IssueDetailView`, change to accept `localPath`:

```swift
struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    let localPath: String  // NEW: workspace local path
    @State private var viewModel = IssueDetailViewModel()

    // In downloadAttachments call, change path:
    // FROM: "\(NSHomeDirectory())/MOI/moi/issues/\(issue.number)/files"
    // TO:   "\(localPath)/issues/\(issue.number)/files"
```

Update `IssueBoardView.navigationDestination`:
```swift
.navigationDestination(for: CachedIssue.self) { issue in
    IssueDetailView(issue: issue, repoFullName: workspace.repoFullName, localPath: workspace.localPath)
}
```

- [ ] **Step 2: I7 — Add stale issue cleanup to GitHubMonitor.poll()**

After the `for remote in remoteIssues` loop, before `try context.save()`:

```swift
// Remove stale issues no longer in remote set
let remoteNumbers = Set(remoteIssues.map(\.number))
for cached in cachedIssues where !remoteNumbers.contains(cached.number) {
    context.delete(cached)
}
```

- [ ] **Step 3: Add test for stale issue cleanup**

In `GitHubMonitorTests.swift`:

```swift
@Test @MainActor func removesStaleIssues() async throws {
    let container = try makeContainer()
    let context = container.mainContext
    // Insert two cached issues
    context.insert(CachedIssue(number: 1, title: "open", projectStatus: "To Do", workspaceName: "test"))
    context.insert(CachedIssue(number: 2, title: "closed", projectStatus: "To Do", workspaceName: "test"))
    try context.save()

    let mock = MockProcessRunner()
    // Remote only returns issue #1 (issue #2 was closed)
    mock.stubSuccess(for: "gh", output: """
    [{"number": 1, "title": "open", "labels": [], "assignees": [], "milestone": null, "updatedAt": "2026-03-10T00:00:00Z", "body": ""}]
    """)
    let client = GitHubCLIClient(processRunner: mock)
    let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

    _ = try await monitor.poll(
        repo: "o/r",
        workspaceName: "test",
        statusResolver: { _, _ in "To Do" }
    )

    let remaining = try context.fetch(FetchDescriptor<CachedIssue>(
        predicate: #Predicate { $0.workspaceName == "test" }
    ))
    #expect(remaining.count == 1)
    #expect(remaining[0].number == 1)
}
```

- [ ] **Step 4: Run tests**

Expected: All tests pass including new test

- [ ] **Step 5: Commit**

```
fix: use workspace localPath for downloads, clean up stale issues on poll
```

---

## Task 9: I1 — Batch status resolution with TaskGroup

**Files:**
- Modify: `DevKit/DevKit/Services/GitHubMonitor.swift`

- [ ] **Step 1: Replace sequential status resolution with TaskGroup**

Refactor the `for remote in remoteIssues` loop to first batch-resolve all statuses:

```swift
// Batch resolve statuses concurrently
let statusMap: [Int: String] = await withTaskGroup(of: (Int, String).self) { group in
    for remote in remoteIssues {
        group.addTask {
            let status = (try? await resolver(repo, remote.number)) ?? "To Do"
            return (remote.number, status)
        }
    }
    var map = [Int: String]()
    for await (number, status) in group {
        map[number] = status
    }
    return map
}

// Then use statusMap[remote.number] in the update loop
for remote in remoteIssues {
    let parsed = LabelParser.parse(remote.labels.map(\.name))
    let attachmentURLs = GHIssue.extractAttachmentURLs(from: remote.body)
    let status = statusMap[remote.number] ?? "To Do"
    // ... rest of update logic unchanged ...
}
```

- [ ] **Step 2: Run tests**

Expected: All tests pass

- [ ] **Step 3: Commit**

```
perf: batch status resolution with TaskGroup in GitHubMonitor
```

---

## Task 10: M1 + M3 + M6 + M8 — Minor fixes

**Files:**
- Modify: `DevKit/DevKit/Models/GitHubModels.swift` (M1, M6)
- Modify: `DevKit/DevKit/Views/Issues/IssueDetailView.swift` (M3, M6)
- Modify: `DevKit/DevKit/Views/Issues/IssueBoardView.swift` (M8)

- [ ] **Step 1: M1 — Remove redundant keyDecodingStrategy**

In `GitHubModels.swift`, simplify ghDecoder:
```swift
extension JSONDecoder {
    static let ghDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
```

- [ ] **Step 2: M6 — Add date parsing to GHComment**

In `GitHubModels.swift`, add a computed property:
```swift
struct GHComment: Codable, Sendable, Identifiable {
    var id: Int
    var body: String
    var author: GHUser
    var createdAt: String

    var createdDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
}
```

In `IssueDetailView.swift`, update comment date display:
```swift
// FROM:
Text(comment.createdAt)
    .font(.caption2)
    .foregroundStyle(.tertiary)

// TO:
if let date = comment.createdDate {
    Text(date, style: .relative)
        .font(.caption2)
        .foregroundStyle(.tertiary)
} else {
    Text(comment.createdAt)
        .font(.caption2)
        .foregroundStyle(.tertiary)
}
```

- [ ] **Step 3: M3 — Use indexed ForEach for attachments**

In `IssueDetailView.swift`:
```swift
// FROM:
ForEach(issue.attachmentURLs, id: \.self) { url in

// TO:
ForEach(Array(issue.attachmentURLs.enumerated()), id: \.offset) { index, url in
```

- [ ] **Step 4: M8 — Cache filtered issues with onChange**

In `IssueBoardView.swift`, replace computed properties with `@State` + `onChange`:

```swift
struct IssueBoardView: View {
    let workspace: Workspace
    @Query private var allIssues: [CachedIssue]
    var viewModel: IssueBoardViewModel?

    @State private var todoIssues: [CachedIssue] = []
    @State private var inProgressIssues: [CachedIssue] = []
    @State private var doneIssues: [CachedIssue] = []

    // init unchanged...

    var body: some View {
        HStack(spacing: 12) {
            // ... use todoIssues, inProgressIssues, doneIssues as before ...
        }
        // ... modifiers ...
        .onChange(of: allIssues) { _, newIssues in
            updateFilteredLists(from: newIssues)
        }
        .onAppear {
            updateFilteredLists(from: allIssues)
        }
    }

    private func updateFilteredLists(from issues: [CachedIssue]) {
        todoIssues = issues.filter { $0.projectStatus == "To Do" || $0.projectStatus == "Todo" }
        inProgressIssues = issues.filter { $0.projectStatus == "In Progress" }
        doneIssues = issues.filter { $0.projectStatus == "Done" }
    }
}
```

NOTE: `CachedIssue` must conform to `Equatable` for `.onChange(of: allIssues)`. SwiftData `@Model` classes already have identity-based equality, so this should work. If it doesn't compile, keep the computed property approach (it's fine for small lists).

- [ ] **Step 5: Run all tests**

Expected: All tests pass

- [ ] **Step 6: Commit**

```
fix: minor cleanup — remove redundant decoder config, parse comment dates, fix attachment identity, cache filtered issues
```

---

## Summary of Changes by Issue

| Issue | Task | Description |
|-------|------|-------------|
| C1 | Task 1 | ProcessRunner → background continuation |
| C2 | Task 2 | GraphQL → variables instead of interpolation |
| C3 | Task 3 | Add NavigationStack in detail pane |
| I1 | Task 9 | Batch status resolution with TaskGroup |
| I2 | Task 4 | Wire up Cmd+R notification observer |
| I3 | Task 5 | Add private(set) to observable properties |
| I4+M4 | Task 6 | Use WorkspaceManager in SettingsView |
| I5 | Task 7 | DI for ProcessRunning in IssueDetailViewModel |
| I6 | Task 8 | Use workspace localPath for downloads |
| I7 | Task 8 | Clean up stale issues on poll |
| I8 | Task 3 | Remove @State from stateless GitHubCLIClient |
| M1 | Task 10 | Remove redundant keyDecodingStrategy |
| M3 | Task 10 | Indexed ForEach for attachments |
| M6 | Task 10 | Parse comment dates |
| M8 | Task 10 | Cache filtered issue lists |
