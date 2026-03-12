import Testing
import Foundation
@testable import DevKit

@Suite("PRDetailViewModel")
struct PRDetailViewModelTests {

    @Test @MainActor func checkMergeabilitySuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN"}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.checkMergeability(repo: "owner/repo", prNumber: 1)

        #expect(vm.mergeability != nil)
        #expect(vm.mergeability?.canMerge == true)
        #expect(vm.mergeability?.mergeable == "MERGEABLE")
        #expect(vm.mergeability?.mergeStateStatus == "CLEAN")
        #expect(vm.mergeError == nil)
    }

    @Test @MainActor func checkMergeabilityConflicting() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"mergeable":"CONFLICTING","mergeStateStatus":"DIRTY"}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.checkMergeability(repo: "owner/repo", prNumber: 1)

        #expect(vm.mergeability != nil)
        #expect(vm.mergeability?.canMerge == false)
        #expect(vm.mergeability?.reasonText == "Has merge conflicts")
    }

    @Test @MainActor func checkMergeabilityBlocked() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"mergeable":"MERGEABLE","mergeStateStatus":"BLOCKED"}
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.checkMergeability(repo: "owner/repo", prNumber: 1)

        #expect(vm.mergeability?.canMerge == false)
        #expect(vm.mergeability?.reasonText == "Merge blocked by branch protection")
    }

    @Test @MainActor func mergeSquashSuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.merge(repo: "owner/repo", prNumber: 42, method: .squash)

        #expect(vm.mergeSuccessMessage == "PR #42 merged via squash")
        #expect(vm.mergeError == nil)
        #expect(vm.isMerging == false)

        // Verify squash flag was passed
        let mergeCall = mock.recordedCommands.first { $0.arguments.contains("merge") }
        #expect(mergeCall != nil)
        #expect(mergeCall?.arguments.contains("--squash") == true)
        #expect(mergeCall?.arguments.contains("--delete-branch") == true)
    }

    @Test @MainActor func mergeRebaseSuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.merge(repo: "owner/repo", prNumber: 10, method: .rebase)

        #expect(vm.mergeSuccessMessage == "PR #10 merged via rebase")
        #expect(vm.mergeError == nil)

        let mergeCall = mock.recordedCommands.first { $0.arguments.contains("merge") }
        #expect(mergeCall?.arguments.contains("--rebase") == true)
    }

    @Test @MainActor func mergeFailureSetsError() async throws {
        let mock = MockProcessRunner()
        // No stub -> throws notFound
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.merge(repo: "owner/repo", prNumber: 1, method: .squash)

        #expect(vm.mergeSuccessMessage == nil)
        #expect(vm.mergeError != nil)
        #expect(vm.isMerging == false)
    }

    @Test @MainActor func loadCommentsSuccess() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"id":1,"body":"LGTM","author":{"login":"reviewer"},"createdAt":"2026-03-10T00:00:00Z"}]
        """)
        let client = GitHubCLIClient(processRunner: mock)
        let vm = PRDetailViewModel(ghClient: client)

        await vm.loadComments(repo: "owner/repo", prNumber: 1)

        #expect(vm.comments.count == 1)
        #expect(vm.comments[0].body == "LGTM")
        #expect(vm.loadError == nil)
    }
}
