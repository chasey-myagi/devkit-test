import Testing
import Foundation
@testable import DevKit

@Suite("IssueDetailViewModel")
struct IssueDetailViewModelTests {

    @Test @MainActor func loadCommentsSuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"id":1,"body":"Fixed it","author":{"login":"dev"},"createdAt":"2026-03-10T00:00:00Z"}]
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let vm = IssueDetailViewModel(ghClient: client, processRunner: mock)

        await vm.loadComments(repo: "owner/repo", issueNumber: 42)

        #expect(vm.comments.count == 1)
        #expect(vm.comments[0].body == "Fixed it")
        #expect(vm.isLoadingComments == false)
    }

    @Test @MainActor func loadCommentsEmpty() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        let vm = IssueDetailViewModel(ghClient: client, processRunner: mock)

        await vm.loadComments(repo: "owner/repo", issueNumber: 1)

        #expect(vm.comments.isEmpty)
        #expect(vm.isLoadingComments == false)
    }

    @Test @MainActor func postCommentSuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        let vm = IssueDetailViewModel(ghClient: client, processRunner: mock)
        vm.newCommentText = "Looks good"

        await vm.postComment(repo: "owner/repo", issueNumber: 10)

        #expect(vm.newCommentText == "")
        #expect(vm.isPostingComment == false)
        let commentCmds = mock.recordedCommands.filter { $0.arguments.contains("comment") }
        #expect(commentCmds.count >= 1)
    }

    @Test @MainActor func postCommentEmptyTextDoesNothing() async throws {
        let mock = MockProcessRunner()
        let client = GitHubCLIClient(processRunner: mock)
        let vm = IssueDetailViewModel(ghClient: client, processRunner: mock)
        vm.newCommentText = "   "

        await vm.postComment(repo: "owner/repo", issueNumber: 1)

        #expect(mock.recordedCommands.isEmpty)
    }

    @Test @MainActor func postCommentFailureSetsError() async throws {
        let mock = MockProcessRunner()
        mock.stubFailure(for: "gh", error: ProcessRunnerError.executionFailed(terminationStatus: 1, stderr: "forbidden"))
        let client = GitHubCLIClient(processRunner: mock)
        let vm = IssueDetailViewModel(ghClient: client, processRunner: mock)
        vm.newCommentText = "Comment"

        await vm.postComment(repo: "owner/repo", issueNumber: 1)

        #expect(vm.downloadError != nil)
        #expect(vm.isPostingComment == false)
    }
}
