import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("IssueBoardViewModel")
struct IssueBoardViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self, configurations: config)
    }

    private func makeIssueJSON(_ issues: [(number: Int, title: String)]) -> String {
        let items = issues.map { issue in
            """
            {"number":\(issue.number),"title":"\(issue.title)","labels":[],"assignees":[],"milestone":null,"updatedAt":"2026-03-10T00:00:00Z","body":""}
            """
        }
        return "[\(items.joined(separator: ","))]"
    }

    @Test @MainActor func worktreeCreatedOnInProgress() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(number: 1, title: "bug", projectStatus: "To Do", workspaceName: "test")
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        // Stub for updateProjectStatus GraphQL calls
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"In Progress"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(1, "bug")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        // worktreeManager should have received git commands for branch + worktree add
        #expect(wtMock.recordedCommands.count >= 1)
        let hasWorktreeAdd = wtMock.recordedCommands.contains { cmd in
            cmd.arguments.contains("worktree") && cmd.arguments.contains("add")
        }
        #expect(hasWorktreeAdd)
    }

    @Test @MainActor func worktreeNotCreatedForOtherStatuses() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(number: 1, title: "bug", projectStatus: "To Do", workspaceName: "test")
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"Done"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(1, "bug")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager
        )

        await vm.updateStatus(issue: cached, newStatus: "Done", workspace: ws)

        // worktreeManager should NOT have been called
        #expect(wtMock.recordedCommands.isEmpty)
    }

    @Test @MainActor func worktreeNotCreatedOnStatusUpdateFailure() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(number: 1, title: "bug", projectStatus: "To Do", workspaceName: "test")
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        // Stub failure for the GraphQL update call
        ghMock.stubFailure(for: "gh", error: GitHubCLIError.mutationFailed("network error"))
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: "[]")
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        // Status should be rolled back
        #expect(cached.projectStatus == "To Do")
        // worktreeManager should NOT have been called
        #expect(wtMock.recordedCommands.isEmpty)
        // Error should be set
        #expect(vm.error != nil)
    }

    @Test @MainActor func attachmentsDownloadedOnInProgress() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(
            number: 3,
            title: "issue with attachments",
            projectStatus: "To Do",
            attachmentURLs: ["https://github.com/user-attachments/assets/image.png"],
            workspaceName: "test"
        )
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"In Progress"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let dlMock = MockProcessRunner()
        dlMock.stubSuccess(for: "curl", output: "")
        let attachmentDownloader = AttachmentDownloader(processRunner: dlMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(3, "issue with attachments")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager,
            attachmentDownloader: attachmentDownloader
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        // curl should have been called to download the attachment
        #expect(dlMock.recordedCommands.count == 1)
        let curlCmd = dlMock.recordedCommands[0]
        #expect(curlCmd.executable == "curl")
        #expect(curlCmd.arguments.contains("-L"))
        #expect(curlCmd.arguments.contains("-o"))
        #expect(curlCmd.arguments.contains("https://github.com/user-attachments/assets/image.png"))
        #expect(cached.attachmentStatus == "downloaded")
    }

    @Test @MainActor func attachmentsNotDownloadedWhenNoURLs() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(number: 1, title: "no attachments", projectStatus: "To Do", workspaceName: "test")
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"In Progress"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let dlMock = MockProcessRunner()
        let attachmentDownloader = AttachmentDownloader(processRunner: dlMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(1, "no attachments")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager,
            attachmentDownloader: attachmentDownloader
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        // curl should NOT have been called
        #expect(dlMock.recordedCommands.isEmpty)
        #expect(cached.attachmentStatus == "none")
    }

    @Test @MainActor func attachmentDownloadFailureSetsFailedStatus() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(
            number: 5,
            title: "failing attachments",
            projectStatus: "To Do",
            attachmentURLs: ["https://example.com/fail.png"],
            workspaceName: "test"
        )
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"In Progress"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        wtMock.stubSuccess(for: "git", output: "")
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let dlMock = MockProcessRunner()
        dlMock.stubFailure(for: "curl", error: ProcessRunnerError.executionFailed(terminationStatus: 22, stderr: "404"))
        let attachmentDownloader = AttachmentDownloader(processRunner: dlMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(5, "failing attachments")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager,
            attachmentDownloader: attachmentDownloader
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        #expect(cached.attachmentStatus == "failed")
    }

    @Test @MainActor func worktreeFailureSetsErrorButKeepsStatus() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp/repo")
        context.insert(ws)
        let cached = CachedIssue(number: 1, title: "bug", projectStatus: "To Do", workspaceName: "test")
        context.insert(cached)
        try context.save()

        let ghMock = MockProcessRunner()
        ghMock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"item1","project":{"id":"proj1","field":{"id":"field1","options":[{"id":"opt1","name":"In Progress"}]}}}]}}}}}
        """)
        let ghClient = GitHubCLIClient(processRunner: ghMock)

        let wtMock = MockProcessRunner()
        // Worktree creation fails
        wtMock.stubFailure(for: "git", error: ProcessRunnerError.notFound("git"))
        let worktreeManager = WorktreeManager(processRunner: wtMock)

        let monitorMock = MockProcessRunner()
        monitorMock.stubSuccess(for: "gh", output: makeIssueJSON([(1, "bug")]))
        let monitor = GitHubMonitor(ghClient: GitHubCLIClient(processRunner: monitorMock), modelContainer: container)

        let vm = IssueBoardViewModel(
            ghClient: ghClient,
            monitor: monitor,
            modelContainer: container,
            worktreeManager: worktreeManager
        )

        await vm.updateStatus(issue: cached, newStatus: "In Progress", workspace: ws)

        // Status should remain "In Progress" (not rolled back)
        #expect(cached.projectStatus == "In Progress")
        // Error should mention worktree failure
        #expect(vm.error?.contains("Worktree") == true)
    }
}
