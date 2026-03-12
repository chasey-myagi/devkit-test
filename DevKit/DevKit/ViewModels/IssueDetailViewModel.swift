import Foundation

@MainActor
@Observable
final class IssueDetailViewModel {
    private let ghClient: GitHubCLIClient
    var isDownloading = false
    var downloadError: String?
    var comments: [GHComment] = []
    var isLoadingComments = false

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
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
        } catch { /* ignore */ }
        for url in urls {
            do {
                let filename = URL(string: url)?.lastPathComponent ?? "attachment"
                let destPath = "\(directory)/\(filename)"
                _ = try await ProcessRunner().run("curl", arguments: [
                    "-L", "-o", destPath, url
                ])
            } catch {
                downloadError = "Failed to download \(url): \(error.localizedDescription)"
            }
        }
    }
}
