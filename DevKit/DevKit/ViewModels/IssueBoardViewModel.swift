import Foundation
import os
import SwiftData

private let logger = Logger(subsystem: "com.chasey.DevKit", category: "IssueBoardViewModel")

@MainActor
@Observable
final class IssueBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let monitor: GitHubMonitor
    private let modelContainer: ModelContainer
    private let worktreeManager: WorktreeManager
    private let attachmentDownloader: AttachmentDownloader
    private weak var coordinator: AgentCoordinator?

    private(set) var isLoading = false
    private(set) var error: String?

    init(
        ghClient: GitHubCLIClient,
        monitor: GitHubMonitor,
        modelContainer: ModelContainer,
        worktreeManager: WorktreeManager = WorktreeManager(),
        attachmentDownloader: AttachmentDownloader = AttachmentDownloader(),
        coordinator: AgentCoordinator? = nil
    ) {
        self.ghClient = ghClient
        self.monitor = monitor
        self.modelContainer = modelContainer
        self.worktreeManager = worktreeManager
        self.attachmentDownloader = attachmentDownloader
        self.coordinator = coordinator
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

        // 状态变为 In Progress 时自动创建 worktree 并下载附件
        if newStatus == "In Progress" {
            do {
                let path = try await worktreeManager.createWorktree(
                    repoPath: workspace.localPath,
                    issueNumber: issue.number
                )
                logger.info("Worktree created at \(path)")
            } catch {
                self.error = "Worktree creation failed: \(error.localizedDescription)"
            }

            // 自动下载附件
            if !issue.attachmentURLs.isEmpty {
                issue.attachmentStatus = "downloading"
                let results = await attachmentDownloader.downloadAttachments(
                    urls: issue.attachmentURLs,
                    localPath: workspace.localPath,
                    issueNumber: issue.number
                )
                let allSucceeded = results.allSatisfy { $0.error == nil }
                issue.attachmentStatus = allSucceeded ? "downloaded" : "failed"
                if !allSucceeded {
                    let failedURLs = results.filter { $0.error != nil }.map { $0.url }
                    logger.error("Some attachments failed to download: \(failedURLs)")
                }
            }

            // 自动入队 Agent 任务
            coordinator?.enqueue(issue: issue, workspace: workspace)
        }
    }
}
