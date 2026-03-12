import Foundation

/// 加载并解析 PR diff 的 ViewModel
@MainActor @Observable
final class PRDiffViewModel {
    private let ghClient: GitHubCLIClient
    private(set) var files: [FileDiff] = []
    private(set) var isLoading = false
    private(set) var error: String?

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
    }

    /// 从 GitHub 加载 PR diff 并解析
    func loadDiff(repo: String, prNumber: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let raw = try await ghClient.fetchPRDiff(repo: repo, prNumber: prNumber)
            files = DiffParser.parse(raw)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
