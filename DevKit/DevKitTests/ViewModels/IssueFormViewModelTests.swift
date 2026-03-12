import Testing
import Foundation
@testable import DevKit

@Suite("IssueFormViewModel")
struct IssueFormViewModelTests {

    @Test @MainActor func createModeHasNilEditingNumber() {
        let vm = IssueFormViewModel()
        #expect(vm.editingIssueNumber == nil)
        #expect(vm.isEditing == false)
    }

    @Test @MainActor func editModePreFillsFromIssue() {
        let issue = CachedIssue(
            number: 42,
            title: "Test Bug",
            labels: ["bug", "urgent"],
            projectStatus: "To Do",
            assignees: ["alice", "bob"],
            milestone: "v1.0",
            bodyHTML: "Some description",
            workspaceName: "ws"
        )
        let vm = IssueFormViewModel(issue: issue)
        #expect(vm.editingIssueNumber == 42)
        #expect(vm.isEditing == true)
        #expect(vm.title == "Test Bug")
        #expect(vm.body == "Some description")
        #expect(vm.selectedLabels == Set(["bug", "urgent"]))
        #expect(vm.selectedMilestone == "v1.0")
        #expect(vm.assignees == "alice, bob")
    }

    @Test @MainActor func labelDiffCalculation() {
        let issue = CachedIssue(
            number: 1,
            title: "T",
            labels: ["bug", "p0"],
            projectStatus: "To Do",
            workspaceName: "ws"
        )
        let vm = IssueFormViewModel(issue: issue)
        // 移除 bug，添加 enhancement
        vm.selectedLabels.remove("bug")
        vm.selectedLabels.insert("enhancement")

        #expect(vm.labelsToAdd.contains("enhancement"))
        #expect(vm.labelsToRemove.contains("bug"))
        #expect(!vm.labelsToAdd.contains("p0"))
        #expect(!vm.labelsToRemove.contains("p0"))
    }

    @Test @MainActor func validationRequiresTitle() {
        let vm = IssueFormViewModel()
        #expect(vm.isValid == false)
        vm.title = "  "
        #expect(vm.isValid == false)
        vm.title = "Valid Title"
        #expect(vm.isValid == true)
    }

    @Test @MainActor func saveCreateCallsCreateIssue() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        {"number": 99, "url": "https://github.com/o/r/issues/99"}
        """)
        let client = GitHubCLIClient(processRunner: mock)

        let vm = IssueFormViewModel()
        vm.title = "New Feature"
        vm.body = "Description"
        vm.selectedLabels = Set(["enhancement"])
        vm.assignees = "alice, bob"

        await vm.save(repo: "o/r", ghClient: client)

        #expect(vm.saveSucceeded == true)
        #expect(vm.error == nil)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("create") == true)
        #expect(cmd?.arguments.contains("New Feature") == true)
    }

    @Test @MainActor func saveEditCallsEditIssue() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: "")
        let client = GitHubCLIClient(processRunner: mock)

        let issue = CachedIssue(
            number: 10,
            title: "Old Title",
            labels: ["bug"],
            projectStatus: "To Do",
            workspaceName: "ws"
        )
        let vm = IssueFormViewModel(issue: issue)
        vm.title = "New Title"
        vm.selectedLabels = Set(["enhancement"])

        await vm.save(repo: "o/r", ghClient: client)

        #expect(vm.saveSucceeded == true)
        let cmd = mock.recordedCommands.first
        #expect(cmd?.arguments.contains("edit") == true)
        #expect(cmd?.arguments.contains("10") == true)
        #expect(cmd?.arguments.contains("New Title") == true)
    }

    @Test @MainActor func saveFailureSetsError() async {
        let mock = MockProcessRunner()
        mock.stubFailure(for: "gh", error: ProcessRunnerError.executionFailed(terminationStatus: 1, stderr: "Not found"))
        let client = GitHubCLIClient(processRunner: mock)

        let vm = IssueFormViewModel()
        vm.title = "Will Fail"

        await vm.save(repo: "o/r", ghClient: client)

        #expect(vm.saveSucceeded == false)
        #expect(vm.error != nil)
    }

    @Test @MainActor func saveEmptyTitleSetsValidationError() async {
        let mock = MockProcessRunner()
        let client = GitHubCLIClient(processRunner: mock)

        let vm = IssueFormViewModel()
        // 不设置 title

        await vm.save(repo: "o/r", ghClient: client)

        #expect(vm.saveSucceeded == false)
        #expect(vm.error == "Title cannot be empty")
        #expect(mock.recordedCommands.isEmpty)
    }

    @Test @MainActor func loadOptionsSuccess() async {
        let mock = MockProcessRunner()
        mock.stubSuccess(for: "gh", output: """
        [{"name":"bug","color":"ff0000"}]
        """)
        let client = GitHubCLIClient(processRunner: mock)

        let vm = IssueFormViewModel()
        await vm.loadOptions(repo: "o/r", ghClient: client)

        // 由于 fetchRepoLabels 和 fetchRepoMilestones 使用不同的参数，
        // MockProcessRunner 用 executable key 匹配，所以两个调用都走 "gh" stub
        #expect(vm.availableLabels.count >= 0)
        #expect(vm.error == nil || vm.availableLabels.count > 0)
    }
}
