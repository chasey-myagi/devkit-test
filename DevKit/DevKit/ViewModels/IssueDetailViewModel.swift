import Foundation

@MainActor
@Observable
final class IssueDetailViewModel {
    private let ghClient: GitHubCLIClient
    private let processRunner: ProcessRunning
    private(set) var isDownloading = false
    private(set) var downloadError: String?
    private(set) var comments: [GHComment] = []
    private(set) var isLoadingComments = false
    private(set) var isPostingComment = false
    var newCommentText: String = ""

    init(ghClient: GitHubCLIClient = GitHubCLIClient(), processRunner: ProcessRunning = ProcessRunner()) {
        self.ghClient = ghClient
        self.processRunner = processRunner
    }

    /// 发布评论
    func postComment(repo: String, issueNumber: Int) async {
        let body = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isPostingComment = true
        defer { isPostingComment = false }
        do {
            try await ghClient.addIssueComment(repo: repo, number: issueNumber, body: body)
            newCommentText = ""
            // 重新加载评论列表
            await loadComments(repo: repo, issueNumber: issueNumber)
        } catch {
            downloadError = error.localizedDescription
        }
    }

    func loadComments(repo: String, issueNumber: Int) async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            comments = try await ghClient.fetchIssueComments(repo: repo, issueNumber: issueNumber)
        } catch {
            downloadError = error.localizedDescription
        }
    }

    func downloadAttachments(urls: [String], to directory: String) async {
        isDownloading = true
        defer { isDownloading = false }
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        } catch { /* directory may already exist */ }
        for url in urls {
            do {
                let filename = URL(string: url)?.lastPathComponent ?? "attachment"
                let destPath = "\(directory)/\(filename)"
                _ = try await processRunner.run("curl", arguments: [
                    "-L", "-o", destPath, url
                ])
            } catch {
                downloadError = "Failed to download \(url): \(error.localizedDescription)"
            }
        }
    }
}
