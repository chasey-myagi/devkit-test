import Foundation

@MainActor
@Observable
final class WorktreeManager {
    private let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    /// 在 repoPath 下创建 worktree，分支名为 fix/{issueNumber}
    /// worktree 路径: repoPath/../worktrees/fix-{issueNumber}
    func createWorktree(repoPath: String, issueNumber: Int) async throws -> String {
        let branch = "fix/\(issueNumber)"
        let worktreePath = URL(fileURLWithPath: repoPath)
            .deletingLastPathComponent()
            .appendingPathComponent("worktrees/fix-\(issueNumber)")
            .path

        // 先尝试创建分支，如果已存在则忽略
        _ = try? await processRunner.run("git", arguments: [
            "-C", repoPath, "branch", branch
        ])

        // 创建 worktree
        _ = try await processRunner.run("git", arguments: [
            "-C", repoPath, "worktree", "add", worktreePath, branch
        ])

        return worktreePath
    }

    /// 移除 worktree
    func removeWorktree(repoPath: String, issueNumber: Int) async throws {
        let worktreePath = URL(fileURLWithPath: repoPath)
            .deletingLastPathComponent()
            .appendingPathComponent("worktrees/fix-\(issueNumber)")
            .path

        _ = try await processRunner.run("git", arguments: [
            "-C", repoPath, "worktree", "remove", worktreePath
        ])
    }
}
