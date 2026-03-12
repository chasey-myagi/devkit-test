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
