# DevKit Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build DevKit macOS App MVP — workspace management, GitHub issue kanban board with status control, issue detail with attachment download, and settings.

**Architecture:** SwiftUI + SwiftData macOS app. All GitHub interaction through `gh` CLI via `Foundation.Process`. Services layer uses protocol-based dependency injection for testability. @Observable view models.

**Tech Stack:** Swift 6.0, SwiftUI, SwiftData, XcodeGen, Swift Testing, `gh` CLI

**Spec:** `docs/design.md`

---

## File Structure

```
DevKit/
├── project.yml                              # XcodeGen project definition
├── DevKit/
│   ├── DevKitApp.swift                      # @main entry, SwiftData container setup
│   ├── ContentView.swift                    # NavigationSplitView (sidebar + detail)
│   │
│   ├── Models/
│   │   ├── Workspace.swift                  # SwiftData @Model — workspace config
│   │   ├── CachedIssue.swift                # SwiftData @Model — local issue cache
│   │   └── GitHubModels.swift               # Codable types for gh CLI JSON output
│   │
│   ├── Services/
│   │   ├── ProcessRunner.swift              # Protocol + impl for running shell commands
│   │   ├── GitHubCLIClient.swift            # gh CLI wrapper (issues, PRs, GraphQL)
│   │   ├── GitHubMonitor.swift              # Polling timer, state change detection
│   │   └── WorkspaceManager.swift           # Workspace CRUD + validation
│   │
│   ├── ViewModels/
│   │   ├── IssueBoardViewModel.swift        # Board state, grouping, drag-drop, optimistic update
│   │   └── IssueDetailViewModel.swift       # Single issue loading, attachment download
│   │
│   ├── Views/
│   │   ├── SidebarView.swift                # Workspace switcher + navigation
│   │   ├── Issues/
│   │   │   ├── IssueBoardView.swift         # Three-column kanban layout
│   │   │   ├── IssueColumnView.swift        # Single column (To Do / In Progress / Done)
│   │   │   ├── IssueCardView.swift          # Issue card within a column
│   │   │   └── IssueDetailView.swift        # Issue detail panel
│   │   └── Settings/
│   │       └── SettingsView.swift           # Settings window (workspace mgmt, gh status, polling)
│   │
│   ├── Utilities/
│   │   └── LabelParser.swift               # Extract severity/priority/customer from label strings
│   │
│   ├── Assets.xcassets/                     # App icon
│   └── .gitignore                           # Ignore xcodeproj, DerivedData, .build
│
└── DevKitTests/
    ├── Services/
    │   ├── MockProcessRunner.swift          # Mock for ProcessRunning protocol
    │   ├── GitHubCLIClientTests.swift       # Test JSON parsing + command construction
    │   ├── GitHubMonitorTests.swift         # Test polling + state change detection
    │   └── WorkspaceManagerTests.swift      # Test CRUD + validation
    ├── Models/
    │   └── GitHubModelsTests.swift          # Test JSON decoding
    └── Utilities/
        └── LabelParserTests.swift           # Test label extraction logic
```

---

## Chunk 1: Project Setup + Data Models

### Task 1: Project Skeleton + XcodeGen

**Files:**
- Create: `DevKit/project.yml`
- Create: `DevKit/DevKit/DevKitApp.swift`
- Create: `DevKit/DevKit/ContentView.swift`
- Create: `DevKit/DevKit/Assets.xcassets/Contents.json`
- Create: `DevKit/.gitignore`

- [ ] **Step 1: Install xcodegen**

Run: `brew install xcodegen`
Expected: xcodegen installed successfully

- [ ] **Step 2: Create project.yml**

```yaml
name: DevKit
options:
  bundleIdPrefix: com.chasey
  deploymentTarget:
    macOS: "15.0"
  xcodeVersion: "26.1"
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "15.0"

targets:
  DevKit:
    type: application
    platform: macOS
    sources:
      - DevKit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.chasey.DevKit
        INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.developer-tools"
        CODE_SIGN_STYLE: Automatic
        # No App Sandbox — this tool needs unrestricted Process access (gh, git, make, claude)

  DevKitTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - DevKitTests
    dependencies:
      - target: DevKit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.chasey.DevKitTests
```

- [ ] **Step 3: Create minimal DevKitApp.swift**

```swift
import SwiftUI
import SwiftData

@main
struct DevKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Workspace.self, CachedIssue.self])

        Settings {
            SettingsView()
        }
    }
}
```

- [ ] **Step 4: Create placeholder ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sidebar")
        } detail: {
            Text("DevKit")
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
```

- [ ] **Step 5: Create asset catalog and .gitignore**

`DevKit/DevKit/Assets.xcassets/Contents.json`:
```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

`DevKit/.gitignore`:
```
*.xcodeproj
DerivedData/
.build/
.swiftpm/
*.xcuserdata
```

- [ ] **Step 6: Generate Xcode project and verify build**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodegen generate`
Expected: "Generated project DevKit.xcodeproj"

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild -project DevKit.xcodeproj -scheme DevKit -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

Note: Build will fail until placeholder models/views are created. Create empty stubs for `Workspace.swift`, `CachedIssue.swift`, `SettingsView.swift` to satisfy compiler.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: scaffold DevKit macOS app with XcodeGen"
```

---

### Task 2: SwiftData Models

**Files:**
- Create: `DevKit/DevKit/Models/Workspace.swift`
- Create: `DevKit/DevKit/Models/CachedIssue.swift`
- Test: `DevKit/DevKitTests/Models/` (tested via service tests)

- [ ] **Step 1: Create Workspace model**

```swift
import Foundation
import SwiftData

@Model
final class Workspace {
    var name: String
    var repoFullName: String
    var localPath: String
    var pollingIntervalSeconds: Int
    var maxConcurrency: Int
    var isActive: Bool

    init(
        name: String,
        repoFullName: String,
        localPath: String,
        pollingIntervalSeconds: Int = 1800,
        maxConcurrency: Int = 2,
        isActive: Bool = false
    ) {
        self.name = name
        self.repoFullName = repoFullName
        self.localPath = localPath
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.maxConcurrency = maxConcurrency
        self.isActive = isActive
    }
}
```

- [ ] **Step 2: Create CachedIssue model**

```swift
import Foundation
import SwiftData

@Model
final class CachedIssue {
    #Unique<CachedIssue>([\.number, \.workspaceName])

    var number: Int
    var title: String
    var labelsRaw: String           // JSON-encoded [String]
    var severity: String?
    var priority: String?
    var customer: String?
    var projectStatus: String       // "To Do" / "In Progress" / "Done"
    var assigneesRaw: String        // JSON-encoded [String]
    var milestone: String?
    var attachmentURLsRaw: String   // JSON-encoded [String]
    var bodyHTML: String?
    var updatedAt: Date
    var workspaceName: String

    var labels: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(labelsRaw.utf8))) ?? [] }
        set { labelsRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var assignees: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(assigneesRaw.utf8))) ?? [] }
        set { assigneesRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var attachmentURLs: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(attachmentURLsRaw.utf8))) ?? [] }
        set { attachmentURLsRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    init(
        number: Int,
        title: String,
        labels: [String] = [],
        severity: String? = nil,
        priority: String? = nil,
        customer: String? = nil,
        projectStatus: String = "To Do",
        assignees: [String] = [],
        milestone: String? = nil,
        attachmentURLs: [String] = [],
        bodyHTML: String? = nil,
        updatedAt: Date = .now,
        workspaceName: String
    ) {
        self.number = number
        self.title = title
        self.labelsRaw = (try? String(data: JSONEncoder().encode(labels), encoding: .utf8)) ?? "[]"
        self.severity = severity
        self.priority = priority
        self.customer = customer
        self.projectStatus = projectStatus
        self.assigneesRaw = (try? String(data: JSONEncoder().encode(assignees), encoding: .utf8)) ?? "[]"
        self.milestone = milestone
        self.attachmentURLsRaw = (try? String(data: JSONEncoder().encode(attachmentURLs), encoding: .utf8)) ?? "[]"
        self.bodyHTML = bodyHTML
        self.updatedAt = updatedAt
        self.workspaceName = workspaceName
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild -project DevKit.xcodeproj -scheme DevKit -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add DevKit/DevKit/Models/
git commit -m "feat: add SwiftData models for Workspace and CachedIssue"
```

---

### Task 3: GitHub API Response Types + Label Parser

**Files:**
- Create: `DevKit/DevKit/Models/GitHubModels.swift`
- Create: `DevKit/DevKit/Utilities/LabelParser.swift`
- Create: `DevKit/DevKitTests/Models/GitHubModelsTests.swift`
- Create: `DevKit/DevKitTests/Utilities/LabelParserTests.swift`

- [ ] **Step 1: Write LabelParser tests**

```swift
import Testing
@testable import DevKit

@Suite("LabelParser")
struct LabelParserTests {

    @Test func extractsSeverity() {
        let labels = ["kind/bug", "severity/s0", "customer/中芯国际"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.severity == "s0")
    }

    @Test func extractsPriority() {
        let labels = ["kind/bug", "priority/p0"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.priority == "p0")
    }

    @Test func extractsCustomer() {
        let labels = ["kind/bug-moi", "customer/安利"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.customer == "安利")
    }

    @Test func handlesNoMatchingLabels() {
        let labels = ["kind/bug", "kind/bug-moi"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.severity == nil)
        #expect(parsed.priority == nil)
        #expect(parsed.customer == nil)
    }

    @Test func handlesEmptyLabels() {
        let parsed = LabelParser.parse([])
        #expect(parsed.severity == nil)
        #expect(parsed.priority == nil)
        #expect(parsed.customer == nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -project DevKit.xcodeproj -scheme DevKitTests -destination 'platform=macOS' 2>&1 | tail -10`
Expected: FAIL — `LabelParser` not found

- [ ] **Step 3: Implement LabelParser**

```swift
import Foundation

enum LabelParser {
    struct ParsedLabels {
        var severity: String?
        var priority: String?
        var customer: String?
    }

    static func parse(_ labels: [String]) -> ParsedLabels {
        var result = ParsedLabels()
        for label in labels {
            if label.hasPrefix("severity/") {
                result.severity = String(label.dropFirst("severity/".count))
            } else if label.hasPrefix("priority/") {
                result.priority = String(label.dropFirst("priority/".count))
            } else if label.hasPrefix("customer/") {
                result.customer = String(label.dropFirst("customer/".count))
            }
        }
        return result
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -project DevKit.xcodeproj -scheme DevKitTests -destination 'platform=macOS' 2>&1 | tail -10`
Expected: All tests PASSED

- [ ] **Step 5: Write GitHubModels tests**

```swift
import Testing
import Foundation
@testable import DevKit

@Suite("GitHubModels")
struct GitHubModelsTests {

    @Test func decodesIssueFromGHCLI() throws {
        let json = """
        {
            "number": 8367,
            "title": "[MOI BUG]: 跨页表合并错误",
            "labels": [
                {"name": "kind/bug"},
                {"name": "kind/bug-moi"},
                {"name": "severity/s0"},
                {"name": "customer/中芯国际"}
            ],
            "assignees": [{"login": "endlesschasey-ai"}],
            "milestone": {"title": "MO Intelligence 4.1 迭代"},
            "updatedAt": "2026-03-10T08:30:00Z",
            "body": "附件：https://github.com/user-attachments/assets/abc123"
        }
        """.data(using: .utf8)!
        let issue = try JSONDecoder.ghDecoder.decode(GHIssue.self, from: json)
        #expect(issue.number == 8367)
        #expect(issue.title == "[MOI BUG]: 跨页表合并错误")
        #expect(issue.labels.count == 4)
        #expect(issue.labels[0].name == "kind/bug")
        #expect(issue.assignees[0].login == "endlesschasey-ai")
        #expect(issue.milestone?.title == "MO Intelligence 4.1 迭代")
    }

    @Test func decodesIssueWithNullMilestone() throws {
        let json = """
        {
            "number": 100,
            "title": "test",
            "labels": [],
            "assignees": [],
            "milestone": null,
            "updatedAt": "2026-03-10T08:30:00Z",
            "body": ""
        }
        """.data(using: .utf8)!
        let issue = try JSONDecoder.ghDecoder.decode(GHIssue.self, from: json)
        #expect(issue.milestone == nil)
    }

    @Test func extractsAttachmentURLsFromBody() {
        let body = """
        问题描述：表格解析错误
        附件：
        https://github.com/user-attachments/assets/abc123.pdf
        https://github.com/user-attachments/assets/def456.docx
        其他文字
        """
        let urls = GHIssue.extractAttachmentURLs(from: body)
        #expect(urls.count == 2)
        #expect(urls[0].contains("abc123"))
        #expect(urls[1].contains("def456"))
    }
}
```

- [ ] **Step 6: Implement GitHubModels**

```swift
import Foundation

struct GHIssue: Codable, Sendable {
    var number: Int
    var title: String
    var labels: [GHLabel]
    var assignees: [GHUser]
    var milestone: GHMilestone?
    var updatedAt: String
    var body: String?

    static func extractAttachmentURLs(from body: String?) -> [String] {
        guard let body else { return [] }
        let pattern = #"https://github\.com/user-attachments/assets/[^\s\)\]\"']+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(body.startIndex..., in: body)
        return regex.matches(in: body, range: range).compactMap { match in
            Range(match.range, in: body).map { String(body[$0]) }
        }
    }
}

struct GHLabel: Codable, Sendable {
    var name: String
}

struct GHUser: Codable, Sendable {
    var login: String
}

struct GHMilestone: Codable, Sendable {
    var title: String
}

struct GHProjectItem: Codable, Sendable {
    var status: GHProjectStatus?

    struct GHProjectStatus: Codable, Sendable {
        var name: String
    }
}

struct GHComment: Codable, Sendable, Identifiable {
    var id: Int
    var body: String
    var author: GHUser
    var createdAt: String
}

extension JSONDecoder {
    static let ghDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
}
```

- [ ] **Step 7: Run all tests**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -project DevKit.xcodeproj -scheme DevKitTests -destination 'platform=macOS' 2>&1 | tail -10`
Expected: All tests PASSED

- [ ] **Step 8: Commit**

```bash
git add DevKit/DevKit/Models/GitHubModels.swift DevKit/DevKit/Utilities/ DevKit/DevKitTests/
git commit -m "feat: add GitHub response models and label parser with tests"
```

---

## Chunk 2: GitHub CLI Client

### Task 4: ProcessRunner

**Files:**
- Create: `DevKit/DevKit/Services/ProcessRunner.swift`
- Create: `DevKit/DevKitTests/Services/MockProcessRunner.swift`
- Create: `DevKit/DevKitTests/Services/ProcessRunnerTests.swift`

- [ ] **Step 1: Write ProcessRunner protocol and mock**

`MockProcessRunner.swift`:
```swift
import Foundation
@testable import DevKit

final class MockProcessRunner: ProcessRunning, @unchecked Sendable {
    var stubbedResults: [String: Result<String, Error>] = [:]
    var recordedCommands: [(executable: String, arguments: [String])] = []

    func run(_ executable: String, arguments: [String]) async throws -> String {
        recordedCommands.append((executable, arguments))
        let key = ([executable] + arguments).joined(separator: " ")
        if let result = stubbedResults[key] {
            return try result.get()
        }
        // Fall back: match by executable name only
        if let result = stubbedResults[executable] {
            return try result.get()
        }
        throw ProcessRunnerError.notFound(executable)
    }

    func stubSuccess(for key: String, output: String) {
        stubbedResults[key] = .success(output)
    }

    func stubFailure(for key: String, error: Error) {
        stubbedResults[key] = .failure(error)
    }
}
```

- [ ] **Step 2: Write ProcessRunner test**

```swift
import Testing
import Foundation
@testable import DevKit

@Suite("ProcessRunner")
struct ProcessRunnerTests {

    @Test func mockRunnerRecordsCommands() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "echo", output: "hello")
        let result = try await mock.run("echo", arguments: ["hello"])
        #expect(result == "hello")
        #expect(mock.recordedCommands.count == 1)
        #expect(mock.recordedCommands[0].executable == "echo")
    }

    @Test func mockRunnerThrowsOnUnstubbed() async {
        let mock = MockProcessRunner()
        await #expect(throws: ProcessRunnerError.self) {
            try await mock.run("unknown", arguments: [])
        }
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Expected: FAIL — `ProcessRunning` protocol not defined

- [ ] **Step 4: Implement ProcessRunner**

```swift
import Foundation

enum ProcessRunnerError: Error, LocalizedError {
    case notFound(String)
    case executionFailed(terminationStatus: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let cmd):
            return "Command not found: \(cmd)"
        case .executionFailed(let status, let stderr):
            return "Process exited with status \(status): \(stderr)"
        }
    }
}

protocol ProcessRunning: Sendable {
    func run(_ executable: String, arguments: [String]) async throws -> String
}

struct ProcessRunner: ProcessRunning {
    func run(_ executable: String, arguments: [String]) async throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Read pipes BEFORE waitUntilExit to avoid deadlock when buffer fills
        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let outStr = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw ProcessRunnerError.executionFailed(
                terminationStatus: process.terminationStatus,
                stderr: errStr
            )
        }
        return outStr
    }
}
```

- [ ] **Step 5: Run tests**

Expected: All PASSED

- [ ] **Step 6: Commit**

```bash
git add DevKit/DevKit/Services/ProcessRunner.swift DevKit/DevKitTests/Services/
git commit -m "feat: add ProcessRunner protocol with mock for testing"
```

---

### Task 5: GitHubCLIClient — Issue Listing

**Files:**
- Create: `DevKit/DevKit/Services/GitHubCLIClient.swift`
- Create: `DevKit/DevKitTests/Services/GitHubCLIClientTests.swift`

- [ ] **Step 1: Write test for issue listing**

```swift
import Testing
import Foundation
@testable import DevKit

@Suite("GitHubCLIClient")
struct GitHubCLIClientTests {

    @Test func fetchesAssignedIssues() async throws {
        let mock = MockProcessRunner()
        let ghOutput = """
        [
            {
                "number": 8367,
                "title": "[MOI BUG]: 跨页表合并",
                "labels": [{"name": "kind/bug"}, {"name": "severity/s0"}],
                "assignees": [{"login": "endlesschasey-ai"}],
                "milestone": {"title": "4.1"},
                "updatedAt": "2026-03-10T08:30:00Z",
                "body": "test body"
            }
        ]
        """
        mock.stubSuccess(for: "gh", output: ghOutput)
        let client = GitHubCLIClient(processRunner: mock)
        let issues = try await client.fetchAssignedIssues(repo: "matrixorigin/matrixflow")
        #expect(issues.count == 1)
        #expect(issues[0].number == 8367)
        #expect(issues[0].title == "[MOI BUG]: 跨页表合并")
    }

    @Test func constructsCorrectGHCommand() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "[]")
        let client = GitHubCLIClient(processRunner: mock)
        _ = try await client.fetchAssignedIssues(repo: "owner/repo")
        #expect(mock.recordedCommands.count == 1)
        let args = mock.recordedCommands[0].arguments
        #expect(args.contains("issue"))
        #expect(args.contains("list"))
        #expect(args.contains("--assignee"))
        #expect(args.contains("@me"))
        #expect(args.contains("--repo"))
        #expect(args.contains("owner/repo"))
    }

    @Test func handlesEmptyIssueList() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "[]")
        let client = GitHubCLIClient(processRunner: mock)
        let issues = try await client.fetchAssignedIssues(repo: "owner/repo")
        #expect(issues.isEmpty)
    }
}
```

- [ ] **Step 2: Run test — expect FAIL**

- [ ] **Step 3: Implement GitHubCLIClient (issue listing)**

```swift
import Foundation

final class GitHubCLIClient: Sendable {
    private let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    func fetchAssignedIssues(repo: String) async throws -> [GHIssue] {
        let jsonFields = "number,title,labels,assignees,milestone,updatedAt,body"
        let output = try await processRunner.run("gh", arguments: [
            "issue", "list",
            "--repo", repo,
            "--assignee", "@me",
            "--state", "open",
            "--limit", "100",
            "--json", jsonFields
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHIssue].self, from: Data(output.utf8))
    }

    func fetchIssueComments(repo: String, issueNumber: Int) async throws -> [GHComment] {
        let output = try await processRunner.run("gh", arguments: [
            "issue", "view", String(issueNumber),
            "--repo", repo,
            "--json", "comments",
            "--jq", ".comments"
        ])
        guard !output.isEmpty else { return [] }
        return try JSONDecoder.ghDecoder.decode([GHComment].self, from: Data(output.utf8))
    }

    func checkAuthStatus() async throws -> String {
        try await processRunner.run("gh", arguments: ["auth", "status"])
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/Services/GitHubCLIClient.swift DevKit/DevKitTests/Services/GitHubCLIClientTests.swift
git commit -m "feat: add GitHubCLIClient with issue listing via gh CLI"
```

---

### Task 6: GitHubCLIClient — Projects.Status (Read + Write)

**Files:**
- Modify: `DevKit/DevKit/Services/GitHubCLIClient.swift`
- Modify: `DevKit/DevKitTests/Services/GitHubCLIClientTests.swift`

- [ ] **Step 1: Write test for fetching project status**

Add to `GitHubCLIClientTests.swift`:

```swift
@Test func fetchesProjectStatus() async throws {
    let mock = MockProcessRunner()
    let graphqlOutput = """
    {
        "data": {
            "repository": {
                "issue": {
                    "projectItems": {
                        "nodes": [
                            {
                                "fieldValueByName": {
                                    "name": "In Progress"
                                }
                            }
                        ]
                    }
                }
            }
        }
    }
    """
    mock.stubSuccess(for: "gh", output: graphqlOutput)
    let client = GitHubCLIClient(processRunner: mock)
    let status = try await client.fetchProjectStatus(repo: "owner/repo", issueNumber: 123)
    #expect(status == "In Progress")
}

@Test func returnsToDoForNullProjectStatus() async throws {
    let mock = MockProcessRunner()
    let graphqlOutput = """
    {
        "data": {
            "repository": {
                "issue": {
                    "projectItems": {
                        "nodes": []
                    }
                }
            }
        }
    }
    """
    mock.stubSuccess(for: "gh", output: graphqlOutput)
    let client = GitHubCLIClient(processRunner: mock)
    let status = try await client.fetchProjectStatus(repo: "owner/repo", issueNumber: 123)
    #expect(status == "To Do")
}
```

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Add GraphQL types and implement**

Add to `GitHubModels.swift`:

```swift
// GraphQL response types for project status
struct GHGraphQLProjectStatusResponse: Codable, Sendable {
    var data: GHGraphQLData

    struct GHGraphQLData: Codable, Sendable {
        var repository: GHGraphQLRepository
    }

    struct GHGraphQLRepository: Codable, Sendable {
        var issue: GHGraphQLIssue
    }

    struct GHGraphQLIssue: Codable, Sendable {
        var projectItems: GHGraphQLProjectItems
    }

    struct GHGraphQLProjectItems: Codable, Sendable {
        var nodes: [GHGraphQLProjectNode]
    }

    struct GHGraphQLProjectNode: Codable, Sendable {
        var fieldValueByName: GHGraphQLFieldValue?
    }

    struct GHGraphQLFieldValue: Codable, Sendable {
        var name: String
    }
}
```

Add to `GitHubCLIClient.swift`:

```swift
func fetchProjectStatus(repo: String, issueNumber: Int) async throws -> String {
    let parts = repo.split(separator: "/")
    guard parts.count == 2 else { throw GitHubCLIError.invalidRepo(repo) }
    let owner = String(parts[0])
    let name = String(parts[1])

    let query = """
    query {
        repository(owner: "\(owner)", name: "\(name)") {
            issue(number: \(issueNumber)) {
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
        "api", "graphql", "-f", "query=\(query)"
    ])
    let response = try JSONDecoder.ghDecoder.decode(
        GHGraphQLProjectStatusResponse.self,
        from: Data(output.utf8)
    )
    let statusName = response.data.repository.issue.projectItems.nodes
        .first?.fieldValueByName?.name
    return statusName ?? "To Do"
}

enum GitHubCLIError: Error {
    case invalidRepo(String)
    case mutationFailed(String)
}
```

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Write test for status mutation**

```swift
@Test func updatesProjectStatus() async throws {
    let mock = MockProcessRunner()
    // First call: get project/item/field IDs
    mock.stubSuccess(for: "gh", output: """
    {
        "data": {
            "repository": {
                "issue": {
                    "projectItems": {
                        "nodes": [{
                            "id": "PVTI_item123",
                            "project": {
                                "id": "PVT_proj456",
                                "field": {
                                    "id": "PVTSSF_field789",
                                    "options": [
                                        {"id": "option_todo", "name": "To Do"},
                                        {"id": "option_inprogress", "name": "In Progress"},
                                        {"id": "option_done", "name": "Done"}
                                    ]
                                }
                            }
                        }]
                    }
                }
            }
        }
    }
    """)
    let client = GitHubCLIClient(processRunner: mock)
    // Should not throw
    try await client.updateProjectStatus(
        repo: "owner/repo",
        issueNumber: 123,
        newStatus: "In Progress"
    )
    #expect(mock.recordedCommands.count >= 1)
}
```

- [ ] **Step 6: Implement updateProjectStatus**

Note: This requires two GraphQL calls — first to get project/item/field IDs, then to mutate. The full implementation involves querying for the project item ID, the status field ID, and the option ID matching the desired status, then calling `updateProjectV2ItemFieldValue` mutation.

```swift
func updateProjectStatus(repo: String, issueNumber: Int, newStatus: String) async throws {
    let parts = repo.split(separator: "/")
    guard parts.count == 2 else { throw GitHubCLIError.invalidRepo(repo) }
    let owner = String(parts[0])
    let name = String(parts[1])

    // Step 1: Get project item ID, project ID, field ID, and option IDs
    let lookupQuery = """
    query {
        repository(owner: "\(owner)", name: "\(name)") {
            issue(number: \(issueNumber)) {
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
        "api", "graphql", "-f", "query=\(lookupQuery)"
    ])

    // Parse lookup response to extract IDs
    let lookupData = try JSONDecoder.ghDecoder.decode(
        GHGraphQLProjectLookupResponse.self,
        from: Data(lookupOutput.utf8)
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

    // Step 2: Mutate
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

Also add to `GitHubModels.swift`:

```swift
struct GHGraphQLProjectLookupResponse: Codable, Sendable {
    var data: DataField
    struct DataField: Codable, Sendable {
        var repository: Repo
    }
    struct Repo: Codable, Sendable {
        var issue: IssueField
    }
    struct IssueField: Codable, Sendable {
        var projectItems: ProjectItems
    }
    struct ProjectItems: Codable, Sendable {
        var nodes: [Node]
    }
    struct Node: Codable, Sendable {
        var id: String
        var project: Project
    }
    struct Project: Codable, Sendable {
        var id: String
        var field: Field?
    }
    struct Field: Codable, Sendable {
        var id: String
        var options: [Option]?
    }
    struct Option: Codable, Sendable {
        var id: String
        var name: String
    }
}
```

- [ ] **Step 7: Run all tests — expect PASS**

- [ ] **Step 8: Commit**

```bash
git add DevKit/DevKit/Services/GitHubCLIClient.swift DevKit/DevKit/Models/GitHubModels.swift DevKit/DevKitTests/
git commit -m "feat: add Projects.Status read/write via GraphQL"
```

---

## Chunk 3: Core Services

### Task 7: WorkspaceManager

**Files:**
- Create: `DevKit/DevKit/Services/WorkspaceManager.swift`
- Create: `DevKit/DevKitTests/Services/WorkspaceManagerTests.swift`

- [ ] **Step 1: Write WorkspaceManager tests**

```swift
import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("WorkspaceManager")
struct WorkspaceManagerTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, configurations: config)
    }

    @Test func addsWorkspace() async throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try await manager.add(name: "moi", repoFullName: "matrixorigin/matrixflow", localPath: "/tmp/test")
        let workspaces = try await manager.listAll()
        #expect(workspaces.count == 1)
        #expect(workspaces[0].name == "moi")
        #expect(workspaces[0].repoFullName == "matrixorigin/matrixflow")
    }

    @Test func rejectsDuplicateName() async throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try await manager.add(name: "moi", repoFullName: "owner/repo", localPath: "/tmp/a")
        await #expect(throws: WorkspaceError.self) {
            try await manager.add(name: "moi", repoFullName: "owner/repo2", localPath: "/tmp/b")
        }
    }

    @Test func deletesWorkspace() async throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try await manager.add(name: "test", repoFullName: "o/r", localPath: "/tmp")
        try await manager.delete(name: "test")
        let workspaces = try await manager.listAll()
        #expect(workspaces.isEmpty)
    }

    @Test func setsActiveWorkspace() async throws {
        let container = try makeContainer()
        let manager = WorkspaceManager(modelContainer: container)
        try await manager.add(name: "a", repoFullName: "o/r1", localPath: "/tmp/a")
        try await manager.add(name: "b", repoFullName: "o/r2", localPath: "/tmp/b")
        try await manager.setActive(name: "b")
        let active = try await manager.getActive()
        #expect(active?.name == "b")
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Implement WorkspaceManager**

```swift
import Foundation
import SwiftData

enum WorkspaceError: Error, LocalizedError {
    case duplicateName(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .duplicateName(let name): return "Workspace '\(name)' already exists"
        case .notFound(let name): return "Workspace '\(name)' not found"
        }
    }
}

@MainActor
@Observable
final class WorkspaceManager {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func add(name: String, repoFullName: String, localPath: String) throws {
        let context = modelContainer.mainContext
        let existing = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.name == name }
        ))
        guard existing.isEmpty else {
            throw WorkspaceError.duplicateName(name)
        }
        let workspace = Workspace(name: name, repoFullName: repoFullName, localPath: localPath)
        context.insert(workspace)
        try context.save()
    }

    func delete(name: String) throws {
        let context = modelContainer.mainContext
        let workspaces = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.name == name }
        ))
        guard let workspace = workspaces.first else {
            throw WorkspaceError.notFound(name)
        }
        context.delete(workspace)
        try context.save()
    }

    func setActive(name: String) throws {
        let context = modelContainer.mainContext
        let all = try context.fetch(FetchDescriptor<Workspace>())
        for ws in all {
            ws.isActive = (ws.name == name)
        }
        try context.save()
    }

    func getActive() throws -> Workspace? {
        let context = modelContainer.mainContext
        let results = try context.fetch(FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.isActive == true }
        ))
        return results.first
    }

    func listAll() throws -> [Workspace] {
        let context = modelContainer.mainContext
        return try context.fetch(FetchDescriptor<Workspace>())
    }
}
```

Note: Tests use `async` wrappers but WorkspaceManager is `@MainActor`. Tests must dispatch to main actor. Adjust test methods to use `@MainActor` attribute or call via `await MainActor.run { }`.

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/Services/WorkspaceManager.swift DevKit/DevKitTests/Services/WorkspaceManagerTests.swift
git commit -m "feat: add WorkspaceManager with CRUD and active workspace support"
```

---

### Task 8: GitHubMonitor

**Files:**
- Create: `DevKit/DevKit/Services/GitHubMonitor.swift`
- Create: `DevKit/DevKitTests/Services/GitHubMonitorTests.swift`

- [ ] **Step 1: Write GitHubMonitor tests**

Uses a `StatusResolver` closure for testability — tests inject a mock resolver that returns predetermined statuses.

```swift
import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("GitHubMonitor")
struct GitHubMonitorTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, configurations: config)
    }

    @Test @MainActor func detectsNewIssues() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"number": 1, "title": "bug A", "labels": [], "assignees": [], "milestone": null, "updatedAt": "2026-03-10T00:00:00Z", "body": ""}]
        """)
        let container = try makeContainer()
        let client = GitHubCLIClient(processRunner: mock)
        let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

        let changes = try await monitor.poll(
            repo: "o/r",
            workspaceName: "test",
            statusResolver: { _, _ in "To Do" }
        )
        #expect(changes.newIssues.count == 1)
        #expect(changes.newIssues[0].number == 1)
    }

    @Test @MainActor func detectsStatusChanges() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let existing = CachedIssue(number: 1, title: "bug", projectStatus: "To Do", workspaceName: "test")
        context.insert(existing)
        try context.save()

        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"number": 1, "title": "bug", "labels": [], "assignees": [], "milestone": null, "updatedAt": "2026-03-10T00:00:00Z", "body": ""}]
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

        let changes = try await monitor.poll(
            repo: "o/r",
            workspaceName: "test",
            statusResolver: { _, _ in "In Progress" }
        )
        #expect(changes.statusChanges.count == 1)
        #expect(changes.statusChanges[0].issueNumber == 1)
        #expect(changes.statusChanges[0].oldStatus == "To Do")
        #expect(changes.statusChanges[0].newStatus == "In Progress")
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Implement GitHubMonitor**

```swift
import Foundation
import SwiftData

struct PollChanges: Sendable {
    var newIssues: [GHIssue] = []
    var statusChanges: [StatusChange] = []

    struct StatusChange: Sendable {
        var issueNumber: Int
        var oldStatus: String
        var newStatus: String
    }
}

/// Resolves project status for an issue. Default impl calls GitHub GraphQL.
/// Tests inject a mock closure.
typealias StatusResolver = @Sendable (String, Int) async throws -> String

@MainActor
@Observable
final class GitHubMonitor {
    private let ghClient: GitHubCLIClient
    private let modelContainer: ModelContainer
    var isPolling = false
    var lastPollDate: Date?
    var lastError: String?
    var consecutiveFailures = 0
    private var pollTimer: Timer?

    init(ghClient: GitHubCLIClient, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.modelContainer = modelContainer
    }

    func startPolling(repo: String, workspaceName: String, interval: TimeInterval) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                _ = try? await self.poll(repo: repo, workspaceName: workspaceName)
            }
        }
        Task {
            _ = try? await poll(repo: repo, workspaceName: workspaceName)
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// statusResolver defaults to calling ghClient.fetchProjectStatus.
    /// Tests inject a mock closure.
    func poll(
        repo: String,
        workspaceName: String,
        statusResolver: StatusResolver? = nil
    ) async throws -> PollChanges {
        isPolling = true
        defer {
            isPolling = false
            lastPollDate = .now
        }

        let resolver = statusResolver ?? { [ghClient] repo, issueNumber in
            try await ghClient.fetchProjectStatus(repo: repo, issueNumber: issueNumber)
        }

        let remoteIssues: [GHIssue]
        do {
            remoteIssues = try await ghClient.fetchAssignedIssues(repo: repo)
            consecutiveFailures = 0
        } catch {
            consecutiveFailures += 1
            lastError = error.localizedDescription
            throw error
        }

        let context = modelContainer.mainContext
        let cachedIssues = try context.fetch(FetchDescriptor<CachedIssue>(
            predicate: #Predicate { $0.workspaceName == workspaceName }
        ))
        let cachedByNumber = Dictionary(uniqueKeysWithValues: cachedIssues.map { ($0.number, $0) })

        var changes = PollChanges()

        for remote in remoteIssues {
            let parsed = LabelParser.parse(remote.labels.map(\.name))
            let attachmentURLs = GHIssue.extractAttachmentURLs(from: remote.body)
            let status = (try? await resolver(repo, remote.number)) ?? "To Do"

            if let cached = cachedByNumber[remote.number] {
                if cached.projectStatus != status {
                    changes.statusChanges.append(.init(
                        issueNumber: remote.number,
                        oldStatus: cached.projectStatus,
                        newStatus: status
                    ))
                }
                cached.title = remote.title
                cached.labels = remote.labels.map(\.name)
                cached.severity = parsed.severity
                cached.priority = parsed.priority
                cached.customer = parsed.customer
                cached.projectStatus = status
                cached.assignees = remote.assignees.map(\.login)
                cached.milestone = remote.milestone?.title
                cached.attachmentURLs = attachmentURLs
                cached.updatedAt = .now
            } else {
                changes.newIssues.append(remote)
                let newCached = CachedIssue(
                    number: remote.number,
                    title: remote.title,
                    labels: remote.labels.map(\.name),
                    severity: parsed.severity,
                    priority: parsed.priority,
                    customer: parsed.customer,
                    projectStatus: status,
                    assignees: remote.assignees.map(\.login),
                    milestone: remote.milestone?.title,
                    attachmentURLs: attachmentURLs,
                    workspaceName: workspaceName
                )
                context.insert(newCached)
            }
        }

        try context.save()
        lastError = nil
        return changes
    }
}
```

- [ ] **Step 4: Adjust tests to work with async implementation, run — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/Services/GitHubMonitor.swift DevKit/DevKitTests/Services/GitHubMonitorTests.swift
git commit -m "feat: add GitHubMonitor with polling and state change detection"
```

---

## Chunk 4: Views — Layout + Issue Board

### Task 9: App Shell + Sidebar

**Files:**
- Modify: `DevKit/DevKit/DevKitApp.swift`
- Modify: `DevKit/DevKit/ContentView.swift`
- Create: `DevKit/DevKit/Views/SidebarView.swift`

- [ ] **Step 1: Implement SidebarView**

```swift
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
        case issues = "Issues"
        case prs = "Pull Requests"

        var id: String { rawValue }
        var icon: String {
            switch self {
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
```

- [ ] **Step 2: Update ContentView with NavigationSplitView**

```swift
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
```

- [ ] **Step 3: Update DevKitApp.swift to wire up services**

```swift
import SwiftUI
import SwiftData

@main
struct DevKitApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Workspace.self, CachedIssue.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)

        Settings {
            SettingsView()
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 4: Build and run visually**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild -project DevKit.xcodeproj -scheme DevKit -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/
git commit -m "feat: add app shell with NavigationSplitView and sidebar"
```

---

### Task 10: Issue Board View

**Files:**
- Create: `DevKit/DevKit/ViewModels/IssueBoardViewModel.swift`
- Create: `DevKit/DevKit/Views/Issues/IssueBoardView.swift`
- Create: `DevKit/DevKit/Views/Issues/IssueColumnView.swift`
- Create: `DevKit/DevKit/Views/Issues/IssueCardView.swift`
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: Create IssueBoardViewModel**

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class IssueBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let monitor: GitHubMonitor
    private let modelContainer: ModelContainer

    var isLoading = false
    var error: String?

    init(ghClient: GitHubCLIClient, monitor: GitHubMonitor, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.monitor = monitor
        self.modelContainer = modelContainer
    }

    func refresh(workspace: Workspace) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await monitor.poll(repo: workspace.repoFullName, workspaceName: workspace.name)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateStatus(issue: CachedIssue, newStatus: String, workspace: Workspace) async {
        let oldStatus = issue.projectStatus
        // Optimistic update
        issue.projectStatus = newStatus

        do {
            try await ghClient.updateProjectStatus(
                repo: workspace.repoFullName,
                issueNumber: issue.number,
                newStatus: newStatus
            )
        } catch {
            // Rollback
            issue.projectStatus = oldStatus
            self.error = "Failed to update status: \(error.localizedDescription)"
        }
    }
}
```

- [ ] **Step 2: Create IssueCardView**

```swift
import SwiftUI

struct IssueCardView: View {
    let issue: CachedIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(issue.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let severity = issue.severity {
                    Text(severity)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(severityColor(severity).opacity(0.2))
                        .foregroundStyle(severityColor(severity))
                        .clipShape(Capsule())
                }
            }

            Text(issue.title)
                .font(.subheadline)
                .lineLimit(2)

            HStack {
                if let customer = issue.customer {
                    Label(customer, systemImage: "building.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(issue.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    private func severityColor(_ s: String) -> Color {
        switch s {
        case "s-1": return .red
        case "s0": return .orange
        case "s1": return .yellow
        case "s2": return .green
        default: return .secondary
        }
    }
}
```

- [ ] **Step 3: Create IssueColumnView**

```swift
import SwiftUI
import SwiftData

struct IssueColumnView: View {
    let title: String
    let status: String
    let issues: [CachedIssue]
    let allIssues: [CachedIssue]        // All issues across columns, for drag-drop lookup
    let onStatusChange: (CachedIssue, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(issues.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Cards
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(issues) { issue in
                        IssueCardView(issue: issue)
                            .draggable(String(issue.number))
                    }
                }
                .padding(8)
            }
        }
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .dropDestination(for: String.self) { items, _ in
            guard let numberStr = items.first,
                  let number = Int(numberStr),
                  let issue = allIssues.first(where: { $0.number == number })
            else { return false }
            onStatusChange(issue, status)
            return true
        }
    }
}
```

- [ ] **Step 4: Create IssueBoardView**

```swift
import SwiftUI
import SwiftData

struct IssueBoardView: View {
    let workspace: Workspace
    @Query private var allIssues: [CachedIssue]
    @State private var viewModel: IssueBoardViewModel?

    init(workspace: Workspace) {
        self.workspace = workspace
        let name = workspace.name
        _allIssues = Query(
            filter: #Predicate<CachedIssue> { $0.workspaceName == name },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    private var todoIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "To Do" || $0.projectStatus == "Todo" }
    }
    private var inProgressIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "In Progress" }
    }
    private var doneIssues: [CachedIssue] {
        allIssues.filter { $0.projectStatus == "Done" }
    }

    var body: some View {
        HStack(spacing: 12) {
            IssueColumnView(title: "To Do", status: "To Do", issues: todoIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
            IssueColumnView(title: "In Progress", status: "In Progress", issues: inProgressIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
            IssueColumnView(title: "Done", status: "Done", issues: doneIssues, allIssues: allIssues) { issue, newStatus in
                Task {
                    await viewModel?.updateStatus(issue: issue, newStatus: newStatus, workspace: workspace)
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel?.refresh(workspace: workspace) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .overlay {
            if viewModel?.isLoading == true {
                ProgressView()
            }
        }
    }
}
```

- [ ] **Step 5: Wire IssueBoardView into ContentView**

Replace the `Text("Issue Board — coming next")` placeholder:

```swift
case .issues:
    if let ws = selectedWorkspace {
        IssueBoardView(workspace: ws)
    }
```

- [ ] **Step 6: Build and verify**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild -project DevKit.xcodeproj -scheme DevKit -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add DevKit/DevKit/ViewModels/ DevKit/DevKit/Views/Issues/ DevKit/DevKit/ContentView.swift
git commit -m "feat: add issue kanban board with drag-drop status change"
```

---

## Chunk 5: Issue Detail + Settings

### Task 11: Issue Detail View

**Files:**
- Create: `DevKit/DevKit/ViewModels/IssueDetailViewModel.swift`
- Create: `DevKit/DevKit/Views/Issues/IssueDetailView.swift`
- Modify: `DevKit/DevKit/Views/Issues/IssueCardView.swift` (add navigation)

- [ ] **Step 1: Create IssueDetailViewModel**

```swift
import Foundation

@MainActor
@Observable
final class IssueDetailViewModel {
    private let ghClient: GitHubCLIClient
    var isDownloading = false
    var downloadError: String?
    var comments: [GHComment] = []
    var isLoadingComments = false

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
    }

    func loadComments(repo: String, issueNumber: Int) async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            comments = try await ghClient.fetchIssueComments(repo: repo, issueNumber: issueNumber)
        } catch {
            downloadError = error.localizedDescription
        }
    }

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
                _ = try await ProcessRunner().run("curl", arguments: [
                    "-L", "-o", destPath, url
                ])
            } catch {
                downloadError = "Failed to download \(url): \(error.localizedDescription)"
            }
        }
    }
}
```

- [ ] **Step 2: Create IssueDetailView**

```swift
import SwiftUI

struct IssueDetailView: View {
    let issue: CachedIssue
    let repoFullName: String
    @State private var viewModel = IssueDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(issue.number)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        statusBadge
                    }
                    Text(issue.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()

                // Labels
                if !issue.labels.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(issue.labels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }

                // Metadata
                GroupBox("Details") {
                    LabeledContent("Severity", value: issue.severity ?? "—")
                    LabeledContent("Priority", value: issue.priority ?? "—")
                    LabeledContent("Customer", value: issue.customer ?? "—")
                    LabeledContent("Milestone", value: issue.milestone ?? "—")
                    LabeledContent("Updated", value: issue.updatedAt.formatted())
                }

                // Attachments
                if !issue.attachmentURLs.isEmpty {
                    GroupBox("Attachments (\(issue.attachmentURLs.count))") {
                        ForEach(issue.attachmentURLs, id: \.self) { url in
                            HStack {
                                Image(systemName: "paperclip")
                                Text(URL(string: url)?.lastPathComponent ?? url)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }

                        Button("Download All") {
                            Task {
                                // Download to workspace issues directory
                                // Note: In real wiring, pass workspace.localPath from parent
                                await viewModel.downloadAttachments(
                                    urls: issue.attachmentURLs,
                                    to: "\(NSHomeDirectory())/MOI/moi/issues/\(issue.number)/files"
                                )
                            }
                        }
                        .disabled(viewModel.isDownloading)
                    }
                }

                // Comments
                GroupBox("Comments (\(viewModel.comments.count))") {
                    if viewModel.isLoadingComments {
                        ProgressView()
                    } else if viewModel.comments.isEmpty {
                        Text("No comments")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.author.login)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(comment.createdAt)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Text(comment.body)
                                    .font(.callout)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("#\(issue.number)")
        .task {
            await viewModel.loadComments(repo: repoFullName, issueNumber: issue.number)
        }
    }

    private var statusBadge: some View {
        Text(issue.projectStatus)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch issue.projectStatus {
        case "In Progress": return .blue
        case "Done": return .green
        default: return .secondary
        }
    }
}

// Simple flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 3: Add navigation from IssueCardView**

Wrap the card in a `NavigationLink` in `IssueColumnView`:

```swift
NavigationLink(value: issue) {
    IssueCardView(issue: issue)
}
.buttonStyle(.plain)
```

And add `.navigationDestination` to `IssueBoardView`:

```swift
.navigationDestination(for: CachedIssue.self) { issue in
    IssueDetailView(issue: issue, repoFullName: workspace.repoFullName)
}
```

- [ ] **Step 4: Build and verify**

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add DevKit/DevKit/ViewModels/IssueDetailViewModel.swift DevKit/DevKit/Views/Issues/IssueDetailView.swift
git commit -m "feat: add issue detail view with labels, metadata, and attachments"
```

---

### Task 12: Settings View

**Files:**
- Create: `DevKit/DevKit/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Implement SettingsView**

```swift
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
```

- [ ] **Step 2: Build and verify**

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add DevKit/DevKit/Views/Settings/SettingsView.swift
git commit -m "feat: add settings with workspace management, GitHub status, and agent config"
```

---

### Task 13: Final Wiring + Keyboard Shortcut

**Files:**
- Modify: `DevKit/DevKit/DevKitApp.swift`
- Modify: `DevKit/DevKit/ContentView.swift`

- [ ] **Step 1: Wire up GitHubMonitor auto-polling on workspace selection**

Update `ContentView.swift` to create and hold the view model and monitor, start polling when workspace is selected:

```swift
@Environment(\.modelContext) private var modelContext
@State private var ghClient = GitHubCLIClient()
@State private var monitor: GitHubMonitor?
@State private var boardViewModel: IssueBoardViewModel?

// Watch selectedWorkspaceName (not the computed property)
.onChange(of: selectedWorkspaceName) { _, newName in
    monitor?.stopPolling()
    guard let ws = workspaces.first(where: { $0.name == newName }) else { return }
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
```

- [ ] **Step 2: Add Cmd+R refresh menu command**

Already handled via `.keyboardShortcut("r", modifiers: .command)` in IssueBoardView toolbar.

Verify it works by adding a menu bar command:

```swift
// In DevKitApp
WindowGroup { ... }
.commands {
    CommandGroup(after: .toolbar) {
        Button("Refresh") {
            NotificationCenter.default.post(name: .refreshIssues, object: nil)
        }
        .keyboardShortcut("r", modifiers: .command)
    }
}

// Add notification name
extension Notification.Name {
    static let refreshIssues = Notification.Name("DevKit.refreshIssues")
}
```

- [ ] **Step 3: Full build and manual test**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild -project DevKit.xcodeproj -scheme DevKit -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run all tests**

Run: `cd /Users/chasey/MOI/devkit/DevKit && xcodebuild test -project DevKit.xcodeproj -scheme DevKitTests -destination 'platform=macOS' 2>&1 | tail -15`
Expected: All tests PASSED

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: wire up auto-polling and keyboard shortcuts — Phase 1 MVP complete"
```

---

## Summary

| Chunk | Tasks | What it delivers |
|-------|-------|------------------|
| 1 | 1-3 | Project skeleton, SwiftData models, GitHub types, label parser |
| 2 | 4-6 | ProcessRunner, GitHubCLIClient (issues + Projects.Status read/write) |
| 3 | 7-8 | WorkspaceManager, GitHubMonitor (polling + cache) |
| 4 | 9-10 | App shell, sidebar, issue kanban board with drag-drop |
| 5 | 11-13 | Issue detail, settings, final wiring |

**Total: 13 tasks, ~65 steps**

After Phase 1 is complete, the app can:
- Manage workspaces (add/delete/switch)
- Poll GitHub for assigned issues every 30min (configurable)
- Display issues in a three-column kanban (To Do / In Progress / Done)
- Drag-drop to change Projects.Status with optimistic update
- View issue details (labels, metadata, attachments)
- Download issue attachments
- Manual refresh with Cmd+R
- Configure polling interval and concurrency in Settings
