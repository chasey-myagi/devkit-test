import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("PRBoardViewModel")
struct PRBoardViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self, configurations: config)
    }

    private func makeReviewJSON(_ reviews: [[String: String]]) -> String {
        if reviews.isEmpty { return "[]" }
        let items = reviews.map { dict -> String in
            let state = dict["state"] ?? "PENDING"
            let login = dict["login"] ?? "user"
            return "{\"state\":\"\(state)\",\"author\":{\"login\":\"\(login)\"}}"
        }
        return "[\(items.joined(separator: ","))]"
    }

    private func makeChecksJSON(_ checks: [[String: String]]) -> String {
        if checks.isEmpty { return "[]" }
        let items = checks.map { dict -> String in
            let ctx = dict["context"] ?? "ci"
            let status = dict["status"] ?? "COMPLETED"
            let conclusion = dict["conclusion"] ?? "SUCCESS"
            return "{\"context\":\"\(ctx)\",\"status\":\"\(status)\",\"conclusion\":\"\(conclusion)\"}"
        }
        return "[\(items.joined(separator: ","))]"
    }

    private func makePRJSON(
        number: Int = 1,
        title: String = "Test PR",
        isDraft: Bool = false,
        additions: Int = 10,
        deletions: Int = 5,
        reviews: [[String: String]] = [],
        statusCheckRollup: [[String: String]] = [],
        body: String? = nil
    ) -> String {
        let reviewsJSON = makeReviewJSON(reviews)
        let checksJSON = makeChecksJSON(statusCheckRollup)
        let bodyField: String
        if let body {
            bodyField = ",\"body\":\"\(body)\""
        } else {
            bodyField = ",\"body\":null"
        }
        return "{\"number\":\(number),\"title\":\"\(title)\",\"isDraft\":\(isDraft),\"additions\":\(additions),\"deletions\":\(deletions),\"reviews\":\(reviewsJSON),\"statusCheckRollup\":\(checksJSON),\"updatedAt\":\"2026-03-10T08:00:00Z\"\(bodyField)}"
    }

    @Test @MainActor func refreshInsertsPRs() async throws {
        let container = try makeContainer()
        let mock = MockProcessRunner()
        let json = "[\(makePRJSON(number: 1, title: "First PR")),\(makePRJSON(number: 2, title: "Second PR"))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 2)
        #expect(vm.error == nil)
    }

    @Test @MainActor func refreshUpdateExistingPR() async throws {
        let container = try makeContainer()

        // Pre-insert a cached PR
        let existing = CachedPR(number: 1, title: "Old title", workspaceName: "test-ws")
        container.mainContext.insert(existing)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        let json = "[\(makePRJSON(number: 1, title: "New title", isDraft: true, additions: 50, deletions: 20))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].title == "New title")
        #expect(prs[0].isDraft == true)
        #expect(prs[0].additions == 50)
        #expect(prs[0].deletions == 20)
    }

    @Test @MainActor func refreshRemovesStalePRs() async throws {
        let container = try makeContainer()

        // Pre-insert a PR that no longer exists remotely
        let stale = CachedPR(number: 999, title: "Stale PR", workspaceName: "test-ws")
        container.mainContext.insert(stale)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        let json = "[\(makePRJSON(number: 1, title: "Active PR"))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].number == 1)
    }

    @Test @MainActor func refreshSetsErrorOnFailure() async throws {
        let container = try makeContainer()
        let mock = MockProcessRunner()
        // No stub → will throw notFound
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func refreshExtractsLinkedIssues() async throws {
        let container = try makeContainer()
        let mock = MockProcessRunner()
        let json = "[\(makePRJSON(number: 5, title: "Fix bug", body: "Closes #42, fixes #99"))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].linkedIssueNumbers.contains(42))
        #expect(prs[0].linkedIssueNumbers.contains(99))
    }

    @Test @MainActor func refreshComputesReviewState() async throws {
        let container = try makeContainer()
        let mock = MockProcessRunner()
        let reviews: [[String: String]] = [
            ["state": "APPROVED", "login": "reviewer1"],
            ["state": "CHANGES_REQUESTED", "login": "reviewer2"]
        ]
        let json = "[\(makePRJSON(number: 10, title: "Mixed reviews", reviews: reviews))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        // CHANGES_REQUESTED takes priority
        #expect(prs[0].reviewState == "CHANGES_REQUESTED")
    }
}
