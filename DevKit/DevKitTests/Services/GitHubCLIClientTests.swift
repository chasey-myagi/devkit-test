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

    @Test func updatesProjectStatus() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"data":{"repository":{"issue":{"projectItems":{"nodes":[{"id":"PVTI_item123","project":{"id":"PVT_proj456","field":{"id":"PVTSSF_field789","options":[{"id":"opt_todo","name":"To Do"},{"id":"opt_ip","name":"In Progress"},{"id":"opt_done","name":"Done"}]}}}]}}}}}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        try await client.updateProjectStatus(repo: "owner/repo", issueNumber: 123, newStatus: "In Progress")
        #expect(mock.recordedCommands.count >= 1)
    }
}
