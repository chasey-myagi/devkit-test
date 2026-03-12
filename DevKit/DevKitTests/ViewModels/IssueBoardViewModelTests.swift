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
