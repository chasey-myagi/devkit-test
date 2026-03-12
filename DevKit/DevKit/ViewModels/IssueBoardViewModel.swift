import Foundation
import SwiftData

@MainActor
@Observable
final class IssueBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let monitor: GitHubMonitor
    private let modelContainer: ModelContainer
    private let worktreeManager: WorktreeManager

    private(set) var isLoading = false
    private(set) var error: String?

    init(
        ghClient: GitHubCLIClient,
        monitor: GitHubMonitor,
        modelContainer: ModelContainer,
        worktreeManager: WorktreeManager = WorktreeManager()
    ) {
        self.ghClient = ghClient
        self.monitor = monitor
        self.modelContainer = modelContainer
        self.worktreeManager = worktreeManager
    }

    func refresh(workspace: Workspace) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await monitor.poll(repo: workspace.repoFullName, workspaceName: workspace.name)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateStatus(issue: CachedIssue, newStatus: String, workspace: Workspace) async {
        let oldStatus = issue.projectStatus
        // Optimistic update
        issue.projectStatus = newStatus

        do {
            try await ghClient.updateProjectStatus(
                repo: workspace.repoFullName,
                issueNumber: issue.number,
                newStatus: newStatus
            )
        } catch {
            // Rollback
            issue.projectStatus = oldStatus
            self.error = "Failed to update status: \(error.localizedDescription)"
            return
        }

        // 状态变为 In Progress 时自动创建 worktree
        if newStatus == "In Progress" {
            do {
                let path = try await worktreeManager.createWorktree(
                    repoPath: workspace.localPath,
                    issueNumber: issue.number
                )
                print("DevKit: Worktree created at \(path)")
            } catch {
                self.error = "Worktree creation failed: \(error.localizedDescription)"
            }
        }
    }
}
