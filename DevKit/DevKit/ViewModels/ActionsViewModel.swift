import Foundation

/// GitHub Actions 管理 ViewModel
@MainActor @Observable
final class ActionsViewModel {
    private let ghClient: GitHubCLIClient
    private(set) var runs: [GHWorkflowRun] = []
    private(set) var selectedRunJobs: [GHWorkflowJob] = []
    private(set) var jobLog: String = ""
    private(set) var isLoading = false
    private(set) var isLoadingLog = false
    private(set) var error: String?

    init(ghClient: GitHubCLIClient = GitHubCLIClient()) {
        self.ghClient = ghClient
    }

    /// 加载 workflow runs 列表
    func loadRuns(repo: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            runs = try await ghClient.fetchWorkflowRuns(repo: repo)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// 加载指定 run 的 jobs
    func loadJobs(repo: String, runId: Int) async {
        do {
            selectedRunJobs = try await ghClient.fetchRunJobs(repo: repo, runId: runId)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// 加载指定 job 的日志
    func loadJobLog(repo: String, jobId: Int) async {
        isLoadingLog = true
        defer { isLoadingLog = false }
        do {
            jobLog = try await ghClient.fetchJobLog(repo: repo, jobId: jobId)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// 重新运行 workflow，完成后自动刷新列表
    func rerun(repo: String, runId: Int) async {
        do {
            try await ghClient.rerunWorkflow(repo: repo, runId: runId)
            await loadRuns(repo: repo)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
