import Testing
import Foundation
@testable import DevKit

@Suite("WorktreeManager")
struct WorktreeManagerTests {

    @Test @MainActor func createsWorktreeWithCorrectBranch() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "git", output: "")
        let manager = WorktreeManager(processRunner: mock)

        let path = try await manager.createWorktree(repoPath: "/tmp/repo", issueNumber: 8367)

        #expect(path.contains("worktrees/fix-8367"))
        #expect(mock.recordedCommands.count >= 2)
        let worktreeCmd = mock.recordedCommands.last!
        #expect(worktreeCmd.arguments.contains("worktree"))
        #expect(worktreeCmd.arguments.contains("add"))
    }

    @Test @MainActor func removesWorktreeWithCorrectPath() async throws {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "git", output: "")
        let manager = WorktreeManager(processRunner: mock)

        try await manager.removeWorktree(repoPath: "/tmp/repo", issueNumber: 8367)

        #expect(mock.recordedCommands.count == 1)
        let cmd = mock.recordedCommands[0]
        #expect(cmd.arguments.contains("worktree"))
        #expect(cmd.arguments.contains("remove"))
    }
}
