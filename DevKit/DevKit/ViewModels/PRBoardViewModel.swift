import Foundation
import SwiftData

@MainActor
@Observable
final class PRBoardViewModel {
    private let ghClient: GitHubCLIClient
    private let modelContainer: ModelContainer

    private(set) var isLoading = false
    private(set) var error: String?

    init(ghClient: GitHubCLIClient, modelContainer: ModelContainer) {
        self.ghClient = ghClient
        self.modelContainer = modelContainer
    }

    func refresh(workspace: Workspace) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let remotePRs = try await ghClient.fetchAuthoredPRs(repo: workspace.repoFullName)
            let context = modelContainer.mainContext
            let workspaceName = workspace.name
            let cachedPRs = try context.fetch(FetchDescriptor<CachedPR>(
                predicate: #Predicate { $0.workspaceName == workspaceName }
            ))
            let cachedByNumber = Dictionary(uniqueKeysWithValues: cachedPRs.map { ($0.number, $0) })

            let remoteNumbers = Set(remotePRs.map(\.number))

            for remote in remotePRs {
                let linkedIssues = GHPullRequest.extractLinkedIssues(from: remote.body)
                if let cached = cachedByNumber[remote.number] {
                    cached.title = remote.title
                    cached.isDraft = remote.isDraft
                    cached.additions = remote.additions
                    cached.deletions = remote.deletions
                    cached.reviewState = remote.aggregatedReviewState
                    cached.checksStatus = remote.aggregatedChecksStatus
                    cached.linkedIssueNumbers = linkedIssues
                    cached.updatedAt = .now
                } else {
                    context.insert(CachedPR(
                        number: remote.number,
                        title: remote.title,
                        isDraft: remote.isDraft,
                        additions: remote.additions,
                        deletions: remote.deletions,
                        reviewState: remote.aggregatedReviewState,
                        checksStatus: remote.aggregatedChecksStatus,
                        linkedIssueNumbers: linkedIssues,
                        workspaceName: workspaceName
                    ))
                }
            }

            // 清理不在远程的 PR
            for cached in cachedPRs where !remoteNumbers.contains(cached.number) {
                context.delete(cached)
            }

            try context.save()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
