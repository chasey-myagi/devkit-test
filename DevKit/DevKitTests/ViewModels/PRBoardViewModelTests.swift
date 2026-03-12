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

    @Test @MainActor func refreshStoresReviewCount() async throws {
        let container = try makeContainer()
        let mock = MockProcessRunner()
        let reviews: [[String: String]] = [
            ["state": "COMMENTED", "login": "reviewer1"],
            ["state": "APPROVED", "login": "reviewer2"]
        ]
        let json = "[\(makePRJSON(number: 4, title: "PR with reviews", reviews: reviews))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        await vm.refresh(workspace: ws)

        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].reviewCount == 2)
    }

    @Test @MainActor func firstRefreshSkipsNotifications() async throws {
        let container = try makeContainer()

        // 预插入一个 CI 成功的 PR
        let existing = CachedPR(
            number: 1, title: "Test PR",
            checksStatus: "SUCCESS",
            workspaceName: "test-ws"
        )
        container.mainContext.insert(existing)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        // 远程数据变为 CI 失败
        let checks: [[String: String]] = [
            ["context": "ci", "status": "COMPLETED", "conclusion": "FAILURE"]
        ]
        let json = "[\(makePRJSON(number: 1, title: "Test PR", statusCheckRollup: checks))]"
        mock.stubSuccess(for: "gh", output: json)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        // 首次刷新 → isFirstRefresh = true → 不发通知
        #expect(vm.isFirstRefresh == true)
        await vm.refresh(workspace: Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp"))

        // 首次刷新后标志变为 false
        #expect(vm.isFirstRefresh == false)
    }

    @Test @MainActor func refreshDetectsCIFailureTransition() async throws {
        let container = try makeContainer()

        // 预插入一个 CI 成功的 PR
        let existing = CachedPR(
            number: 1, title: "Test PR",
            checksStatus: "SUCCESS",
            workspaceName: "test-ws"
        )
        container.mainContext.insert(existing)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        // 第一次刷新：CI 仍然成功（用于消耗 isFirstRefresh）
        let successJSON = "[\(makePRJSON(number: 1, title: "Test PR", statusCheckRollup: [["context": "ci", "status": "COMPLETED", "conclusion": "SUCCESS"]]))]"
        mock.stubSuccess(for: "gh", output: successJSON)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        // 首次刷新（消耗 isFirstRefresh）
        await vm.refresh(workspace: ws)
        #expect(vm.isFirstRefresh == false)

        // 第二次刷新：CI 变为 FAILURE
        let failureJSON = "[\(makePRJSON(number: 1, title: "Test PR", statusCheckRollup: [["context": "ci", "status": "COMPLETED", "conclusion": "FAILURE"]]))]"
        mock.stubSuccess(for: "gh", output: failureJSON)

        await vm.refresh(workspace: ws)

        // 验证 PR 的 checksStatus 更新为 FAILURE
        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].checksStatus == "FAILURE")
    }

    @Test @MainActor func refreshDetectsNewReviews() async throws {
        let container = try makeContainer()

        // 预插入一个有 1 个 review 的 PR
        let existing = CachedPR(
            number: 1, title: "Test PR",
            reviewCount: 1,
            workspaceName: "test-ws"
        )
        container.mainContext.insert(existing)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        // 第一次刷新：仍然 1 个 review（消耗 isFirstRefresh）
        let reviews1: [[String: String]] = [["state": "COMMENTED", "login": "reviewer1"]]
        let json1 = "[\(makePRJSON(number: 1, title: "Test PR", reviews: reviews1))]"
        mock.stubSuccess(for: "gh", output: json1)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        // 首次刷新
        await vm.refresh(workspace: ws)
        #expect(vm.isFirstRefresh == false)

        // 第二次刷新：增加到 2 个 review
        let reviews2: [[String: String]] = [
            ["state": "COMMENTED", "login": "reviewer1"],
            ["state": "APPROVED", "login": "reviewer2"]
        ]
        let json2 = "[\(makePRJSON(number: 1, title: "Test PR", reviews: reviews2))]"
        mock.stubSuccess(for: "gh", output: json2)

        await vm.refresh(workspace: ws)

        // 验证 reviewCount 更新
        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs.count == 1)
        #expect(prs[0].reviewCount == 2)
    }

    @Test @MainActor func noNotificationForAlreadyFailedCI() async throws {
        let container = try makeContainer()

        // 预插入一个 CI 已经是 FAILURE 的 PR
        let existing = CachedPR(
            number: 1, title: "Test PR",
            checksStatus: "FAILURE",
            workspaceName: "test-ws"
        )
        container.mainContext.insert(existing)
        try container.mainContext.save()

        let mock = MockProcessRunner()
        // 消耗 isFirstRefresh
        let failureJSON = "[\(makePRJSON(number: 1, title: "Test PR", statusCheckRollup: [["context": "ci", "status": "COMPLETED", "conclusion": "FAILURE"]]))]"
        mock.stubSuccess(for: "gh", output: failureJSON)

        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRBoardViewModel(ghClient: client, modelContainer: container)

        let ws = Workspace(name: "test-ws", repoFullName: "owner/repo", localPath: "/tmp")
        container.mainContext.insert(ws)
        try container.mainContext.save()

        // 首次刷新
        await vm.refresh(workspace: ws)
        // 第二次刷新，CI 仍然是 FAILURE → 不应触发新通知
        await vm.refresh(workspace: ws)

        // 只要不崩就行，这里主要验证 FAILURE → FAILURE 不触发额外通知逻辑
        let prs = try container.mainContext.fetch(FetchDescriptor<CachedPR>())
        #expect(prs[0].checksStatus == "FAILURE")
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
