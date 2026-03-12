import Foundation

@MainActor
final class WorktreeManager {
    private let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    /// 在 repoPath 下创建 worktree，分支名为 fix/{issueNumber}
    /// worktree 路径: repoPath/../worktrees/fix-{issueNumber}
    /// 如果 worktree 已存在则静默返回其路径（幂等）
    func createWorktree(repoPath: String, issueNumber: Int) async throws -> String {
        let branch = "fix/\(issueNumber)"
        let path = worktreePath(repoPath: repoPath, issueNumber: issueNumber)

        // 如果 worktree 已存在，直接返回
        if FileManager.default.fileExists(atPath: path) {
            return path
        }

        // 先尝试创建分支，如果已存在则忽略
        _ = try? await processRunner.run("git", arguments: [
            "-C", repoPath, "branch", branch
        ])

        // 创建 worktree
        _ = try await processRunner.run("git", arguments: [
            "-C", repoPath, "worktree", "add", path, branch
        ])

        return path
    }

    /// 移除 worktree
    func removeWorktree(repoPath: String, issueNumber: Int) async throws {
        let path = worktreePath(repoPath: repoPath, issueNumber: issueNumber)

        _ = try await processRunner.run("git", arguments: [
            "-C", repoPath, "worktree", "remove", path
        ])
    }

    private func worktreePath(repoPath: String, issueNumber: Int) -> String {
        URL(fileURLWithPath: repoPath)
            .deletingLastPathComponent()
            .appendingPathComponent("worktrees/fix-\(issueNumber)")
            .path
    }
}
