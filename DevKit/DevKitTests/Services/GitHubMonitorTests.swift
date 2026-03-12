import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("GitHubMonitor")
struct GitHubMonitorTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self, configurations: config)
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

    @Test @MainActor func rateLimitSetsRateLimitedUntil() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(
            for: "gh",
            error: ProcessRunnerError.executionFailed(
                terminationStatus: 1,
                stderr: "HTTP 403: API rate limit exceeded"
            )
        )
        let container = try makeContainer()
        let client = GitHubCLIClient(processRunner: mock)
        let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

        do {
            _ = try await monitor.poll(
                repo: "o/r",
                workspaceName: "test",
                statusResolver: { _, _ in "To Do" }
            )
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }

        #expect(monitor.rateLimitedUntil != nil)
        // rateLimitedUntil 应该在未来约 15 分钟
        if let until = monitor.rateLimitedUntil {
            let interval = until.timeIntervalSinceNow
            #expect(interval > 800) // 至少 800 秒
            #expect(interval <= 900) // 最多 900 秒
        }
    }

    @Test @MainActor func rateLimitSkipsPollDuringCooldown() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(
            for: "gh",
            error: ProcessRunnerError.executionFailed(
                terminationStatus: 1,
                stderr: "HTTP 403: API rate limit exceeded"
            )
        )
        let container = try makeContainer()
        let client = GitHubCLIClient(processRunner: mock)
        let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

        // 第一次触发 rate limit
        _ = try? await monitor.poll(
            repo: "o/r",
            workspaceName: "test",
            statusResolver: { _, _ in "To Do" }
        )
        #expect(monitor.rateLimitedUntil != nil)

        // 记录调用次数
        let callCountBefore = mock.recordedCommands.count

        // 第二次 poll 应该跳过（仍在冷却期）
        do {
            _ = try await monitor.poll(
                repo: "o/r",
                workspaceName: "test",
                statusResolver: { _, _ in "To Do" }
            )
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected - rate limited
        }

        // 不应该有新的 process 调用
        #expect(mock.recordedCommands.count == callCountBefore)
    }

    @Test @MainActor func rateLimitDoesNotIncrementConsecutiveFailures() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(
            for: "gh",
            error: ProcessRunnerError.executionFailed(
                terminationStatus: 1,
                stderr: "HTTP 403: API rate limit exceeded"
            )
        )
        let container = try makeContainer()
        let client = GitHubCLIClient(processRunner: mock)
        let monitor = GitHubMonitor(ghClient: client, modelContainer: container)

        _ = try? await monitor.poll(
            repo: "o/r",
            workspaceName: "test",
            statusResolver: { _, _ in "To Do" }
        )

        // Rate limit 错误不应增加 consecutiveFailures 计数
        #expect(monitor.consecutiveFailures == 0)
    }

    @Test @MainActor func removesStaleIssues() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(CachedIssue(number: 1, title: "open", projectStatus: "To Do", workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "closed", projectStatus: "To Do", workspaceName: "test"))
        try context.save()

        let mock = MockProcessRunner()
        // Remote only returns issue #1 — issue #2 was closed
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
}
