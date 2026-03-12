import Testing
import Foundation
@testable import DevKit

@Suite("GitHubCLIClient")
struct GitHubCLIClientTests {

    @Test func fetchesAssignedIssues() async throws {
        let mock = MockProcessRunner()
        let ghOutput = """
        [{"number": 8367, "title": "[MOI BUG]: 跨页表合并", "labels": [{"name": "kind/bug"}, {"name": "severity/s0"}], "assignees": [{"login": "endlesschasey-ai"}], "milestone": {"title": "4.1"}, "updatedAt": "2026-03-10T08:30:00Z", "body": "test body"}]
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
    }

    @Test func handlesEmptyIssueList() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "[]")
        let client = GitHubCLIClient(processRunner: mock)
        let issues = try await client.fetchAssignedIssues(repo: "owner/repo")
        #expect(issues.isEmpty)
    }

    @Test func fetchesProjectStatus() async throws {
        let mock = MockProcessRunner()
        let graphqlOutput = """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"fieldValueByName":{"name":"In Progress"}}]}}}}}
        """
        mock.stubSuccess(for: "gh", output: graphqlOutput)
        let client = GitHubCLIClient(processRunner: mock)
        let status = try await client.fetchProjectStatus(repo: "owner/repo", issueNumber: 123)
        #expect(status == "In Progress")
    }

    @Test func returnsToDoForNullProjectStatus() async throws {
        let mock = MockProcessRunner()
        let graphqlOutput = """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[]}}}}}
        """
        mock.stubSuccess(for: "gh", output: graphqlOutput)
        let client = GitHubCLIClient(processRunner: mock)
        let status = try await client.fetchProjectStatus(repo: "owner/repo", issueNumber: 123)
        #expect(status == "To Do")
    }

    @Test func checksPRMergeability() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN"}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let result = try await client.checkPRMergeable(repo: "owner/repo", prNumber: 4)
        #expect(result.mergeable == "MERGEABLE")
        #expect(result.mergeStateStatus == "CLEAN")
        #expect(result.canMerge == true)
    }

    @Test func mergesPRWithSquash() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        try await client.mergePR(repo: "owner/repo", prNumber: 4, method: .squash)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("merge") == true)
        #expect(cmd?.arguments.contains("--squash") == true)
        #expect(cmd?.arguments.contains("--delete-branch") == true)
        #expect(cmd?.arguments.contains("4") == true)
    }

    @Test func mergesPRWithRebase() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        try await client.mergePR(repo: "owner/repo", prNumber: 5, method: .rebase)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("--rebase") == true)
        #expect(cmd?.arguments.contains("5") == true)
    }

    @Test func updatesProjectStatus() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"PVTI_item123","project":{"id":"PVT_proj456","field":{"id":"PVTSSF_field789","options":[{"id":"opt_todo","name":"To Do"},{"id":"opt_ip","name":"In Progress"},{"id":"opt_done","name":"Done"}]}}}]}}}}}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        try await client.updateProjectStatus(repo: "owner/repo", issueNumber: 123, newStatus: "In Progress")
        #expect(mock.recordedCommands.count >= 1)
    }

    // MARK: - Actions

    @Test func fetchWorkflowRunsDecoding() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"databaseId":100,"displayTitle":"CI","name":"build","headBranch":"main","status":"completed","conclusion":"success","event":"push","createdAt":"2026-03-12T00:00:00Z","updatedAt":"2026-03-12T00:05:00Z","url":"https://github.com/o/r/actions/runs/100"}]
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let runs = try await client.fetchWorkflowRuns(repo: "o/r")
        #expect(runs.count == 1)
        #expect(runs[0].databaseId == 100)
        #expect(runs[0].displayTitle == "CI")
        #expect(runs[0].conclusion == "success")
        #expect(runs[0].statusIcon == "checkmark.circle.fill")
    }

    @Test func fetchWorkflowRunsEmpty() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        let runs = try await client.fetchWorkflowRuns(repo: "o/r")
        #expect(runs.isEmpty)
    }

    @Test func fetchRunJobsDecoding() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"id":200,"name":"build","status":"completed","conclusion":"success","startedAt":"2026-03-12T00:00:00Z","completedAt":"2026-03-12T00:02:00Z"}]
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let jobs = try await client.fetchRunJobs(repo: "o/r", runId: 100)
        #expect(jobs.count == 1)
        #expect(jobs[0].name == "build")
        #expect(jobs[0].conclusion == "success")
    }

    @Test func fetchJobLogReturnsString() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "Step 1: Checkout\nStep 2: Build\nStep 3: Test")
        let client = GitHubCLIClient(processRunner: mock)
        let log = try await client.fetchJobLog(repo: "o/r", jobId: 200)
        #expect(log.contains("Step 1: Checkout"))
        #expect(log.contains("Step 3: Test"))
    }

    @Test func rerunWorkflowSendsCorrectArgs() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        try await client.rerunWorkflow(repo: "o/r", runId: 100)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("rerun") == true)
        #expect(cmd?.arguments.contains("100") == true)
        #expect(cmd?.arguments.contains("--failed") == true)
    }

    @Test func rerunWorkflowAllJobs() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        try await client.rerunWorkflow(repo: "o/r", runId: 100, failedOnly: false)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("rerun") == true)
        #expect(cmd?.arguments.contains("--failed") == false)
    }

    @Test func workflowRunStatusIcons() {
        // 测试各状态的图标映射
        let successRun = GHWorkflowRun(databaseId: 1, displayTitle: "CI", name: "build", headBranch: "main", status: "completed", conclusion: "success", event: "push", createdAt: "", updatedAt: "", url: "")
        #expect(successRun.statusIcon == "checkmark.circle.fill")

        let failedRun = GHWorkflowRun(databaseId: 2, displayTitle: "CI", name: "build", headBranch: "main", status: "completed", conclusion: "failure", event: "push", createdAt: "", updatedAt: "", url: "")
        #expect(failedRun.statusIcon == "xmark.circle.fill")

        let inProgressRun = GHWorkflowRun(databaseId: 3, displayTitle: "CI", name: "build", headBranch: "main", status: "in_progress", conclusion: nil, event: "push", createdAt: "", updatedAt: "", url: "")
        #expect(inProgressRun.statusIcon == "circle.dotted.circle")

        let queuedRun = GHWorkflowRun(databaseId: 4, displayTitle: "CI", name: "build", headBranch: "main", status: "queued", conclusion: nil, event: "push", createdAt: "", updatedAt: "", url: "")
        #expect(queuedRun.statusIcon == "clock.circle")
    }
}
