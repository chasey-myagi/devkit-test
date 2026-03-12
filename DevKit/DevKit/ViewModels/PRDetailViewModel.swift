import Foundation

@MainActor
@Observable
final class PRDetailViewModel {
    private let ghClient: GitHubCLIClient
    private(set) var comments: [GHComment] = []
    private(set) var isLoadingComments = false
    private(set) var loadError: String?

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
    }

    func loadComments(repo: String, prNumber: Int) async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            comments = try await ghClient.fetchPRReviewComments(repo: repo, prNumber: prNumber)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}
