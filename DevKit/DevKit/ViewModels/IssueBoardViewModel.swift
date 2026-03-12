import Foundation
import SwiftData

@MainActor
@Observable
final class IssueBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let monitor: GitHubMonitor
    private let modelContainer: ModelContainer

    private(set) var isLoading = false
    private(set) var error: String?

    init(ghClient: GitHubCLIClient, monitor: GitHubMonitor, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.monitor = monitor
        self.modelContainer = modelContainer
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
        }
    }
}
