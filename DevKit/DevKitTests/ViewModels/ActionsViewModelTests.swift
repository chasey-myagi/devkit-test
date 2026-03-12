import Testing
import Foundation
@testable import DevKit

@Suite("ActionsViewModel")
struct ActionsViewModelTests {

    private let sampleRunJSON = """
    [{"databaseId":100,"displayTitle":"CI","name":"build","headBranch":"main","status":"completed","conclusion":"success","event":"push","createdAt":"2026-03-12T00:00:00Z","updatedAt":"2026-03-12T00:05:00Z","url":"https://github.com/o/r/actions/runs/100"}]
    """

    private let sampleJobsJSON = """
    [{"id":200,"name":"build","status":"completed","conclusion":"success","startedAt":"2026-03-12T00:00:00Z","completedAt":"2026-03-12T00:02:00Z"}]
    """

    @Test @MainActor func loadRunsSuccess() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: sampleRunJSON)
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadRuns(repo: "o/r")

        #expect(vm.runs.count == 1)
        #expect(vm.runs[0].displayTitle == "CI")
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func loadRunsError() async {
        let mock = MockProcessRunner()
        // 不设 stub -> 抛出 notFound 错误
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadRuns(repo: "o/r")

        #expect(vm.runs.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test @MainActor func loadJobsSuccess() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: sampleJobsJSON)
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadJobs(repo: "o/r", runId: 100)

        #expect(vm.selectedRunJobs.count == 1)
        #expect(vm.selectedRunJobs[0].name == "build")
        #expect(vm.error == nil)
    }

    @Test @MainActor func loadJobLogSuccess() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "Step 1: Checkout\nStep 2: Build\nStep 3: Done")
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadJobLog(repo: "o/r", jobId: 200)

        #expect(vm.jobLog.contains("Step 1: Checkout"))
        #expect(vm.error == nil)
        #expect(vm.isLoadingLog == false)
    }

    @Test @MainActor func loadJobLogError() async {
        let mock = MockProcessRunner()
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.loadJobLog(repo: "o/r", jobId: 200)

        #expect(vm.jobLog.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLoadingLog == false)
    }

    @Test @MainActor func rerunTriggersRefresh() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: sampleRunJSON)
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.rerun(repo: "o/r", runId: 100)

        // rerun 后应自动调用 loadRuns 刷新列表
        #expect(vm.runs.count == 1)
        #expect(vm.error == nil)
        // 应有 rerun 和 list 两次 gh 调用
        #expect(mock.recordedCommands.count == 2)
    }

    @Test @MainActor func rerunError() async {
        let mock = MockProcessRunner()
        // 不设 stub -> rerun 失败
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))
        await vm.rerun(repo: "o/r", runId: 100)

        #expect(vm.error != nil)
    }

    @Test @MainActor func loadRunsClearsOldError() async {
        let mock = MockProcessRunner()
        let vm = ActionsViewModel(ghClient: GitHubCLIClient(processRunner: mock))

        // 第一次失败
        await vm.loadRuns(repo: "o/r")
        #expect(vm.error != nil)

        // 第二次成功
        mock.stubSuccess(for: "gh", output: sampleRunJSON)
        await vm.loadRuns(repo: "o/r")
        #expect(vm.error == nil)
        #expect(vm.runs.count == 1)
    }
}
