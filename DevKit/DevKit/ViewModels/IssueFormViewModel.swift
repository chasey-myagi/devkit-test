import Foundation

@MainActor
@Observable
final class IssueFormViewModel {
    // 表单字段
    var title: String = ""
    var body: String = ""
    var selectedLabels: Set<String> = []
    var assignees: String = ""
    var selectedMilestone: String? = nil

    // 编辑模式：非 nil 表示编辑已有 issue
    let editingIssueNumber: Int?

    // 原始标签，用于计算 diff
    private var originalLabels: Set<String> = []

    // 可选项
    private(set) var availableLabels: [GHLabelInfo] = []
    private(set) var availableMilestones: [GHMilestoneInfo] = []

    // 状态
    private(set) var isLoadingOptions = false
    private(set) var isSaving = false
    private(set) var error: String?
    private(set) var saveSucceeded = false

    /// 创建模式
    init() {
        self.editingIssueNumber = nil
    }

    /// 编辑模式：用现有 issue 数据预填表单
    init(issue: CachedIssue) {
        self.editingIssueNumber = issue.number
        self.title = issue.title
        self.body = issue.bodyHTML ?? ""
        self.selectedLabels = Set(issue.labels)
        self.originalLabels = Set(issue.labels)
        self.assignees = issue.assignees.joined(separator: ", ")
        self.selectedMilestone = issue.milestone
    }

    var isEditing: Bool {
        editingIssueNumber != nil
    }

    /// 计算需要添加的标签
    var labelsToAdd: [String] {
        Array(selectedLabels.subtracting(originalLabels))
    }

    /// 计算需要移除的标签
    var labelsToRemove: [String] {
        Array(originalLabels.subtracting(selectedLabels))
    }

    /// 标题是否有效
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 加载仓库标签和里程碑
    func loadOptions(repo: String, ghClient: GitHubCLIClient) async {
        isLoadingOptions = true
        defer { isLoadingOptions = false }
        do {
            async let labels = ghClient.fetchRepoLabels(repo: repo)
            async let milestones = ghClient.fetchRepoMilestones(repo: repo)
            availableLabels = try await labels
            availableMilestones = try await milestones
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// 保存（创建或编辑）
    func save(repo: String, ghClient: GitHubCLIClient) async {
        guard isValid else {
            error = "Title cannot be empty"
            return
        }
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            if let number = editingIssueNumber {
                // 编辑模式
                try await ghClient.editIssue(
                    repo: repo,
                    number: number,
                    title: title,
                    body: body,
                    addLabels: labelsToAdd,
                    removeLabels: labelsToRemove
                )
            } else {
                // 创建模式
                let assigneeList = assignees
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                _ = try await ghClient.createIssue(
                    repo: repo,
                    title: title,
                    body: body,
                    labels: Array(selectedLabels),
                    assignees: assigneeList,
                    milestone: selectedMilestone
                )
            }
            saveSucceeded = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
