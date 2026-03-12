import Foundation

@MainActor
@Observable
final class PRDetailViewModel {
    private let ghClient: GitHubCLIClient
    private(set) var comments: [GHComment] = []
    private(set) var isLoadingComments = false
    private(set) var loadError: String?
    private(set) var isPostingComment = false
    var newCommentText: String = ""

    // Merge state
    private(set) var mergeability: PRMergeability?
    private(set) var isCheckingMergeability = false
    private(set) var isMerging = false
    private(set) var mergeSuccessMessage: String?
    private(set) var mergeError: String?

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
    }

    /// 发布 PR 评论
    func postComment(repo: String, prNumber: Int) async {
        let body = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isPostingComment = true
        defer { isPostingComment = false }
        do {
            try await ghClient.addPRComment(repo: repo, number: prNumber, body: body)
            newCommentText = ""
            await loadComments(repo: repo, prNumber: prNumber)
        } catch {
            loadError = error.localizedDescription
        }
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

    func checkMergeability(repo: String, prNumber: Int) async {
        isCheckingMergeability = true
        defer { isCheckingMergeability = false }
        do {
            mergeability = try await ghClient.checkPRMergeable(repo: repo, prNumber: prNumber)
            mergeError = nil
        } catch {
            mergeError = error.localizedDescription
        }
    }

    func merge(repo: String, prNumber: Int, method: PRMergeMethod) async {
        isMerging = true
        mergeError = nil
        mergeSuccessMessage = nil
        defer { isMerging = false }
        do {
            try await ghClient.mergePR(repo: repo, prNumber: prNumber, method: method)
            mergeSuccessMessage = "PR #\(prNumber) merged via \(method.rawValue)"
        } catch {
            mergeError = error.localizedDescription
        }
    }

    func dismissMergeSuccess() {
        mergeSuccessMessage = nil
    }
}
