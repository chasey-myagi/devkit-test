import Foundation

/// 搜索防抖 + 多维过滤 ViewModel
@MainActor @Observable
final class SearchFilterViewModel {
    var searchText = ""
    var selectedLabels: Set<String> = []
    var selectedAssignee: String?
    var selectedMilestone: String?
    var selectedPriority: String?

    // 防抖后的搜索词
    var debouncedSearchText = ""
    private var debounceTask: Task<Void, Never>?

    /// 更新搜索文本，自动防抖 300ms
    func updateSearch(_ text: String) {
        searchText = text
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            debouncedSearchText = text
        }
    }

    /// 清除所有过滤条件
    func clearAll() {
        searchText = ""
        debouncedSearchText = ""
        selectedLabels = []
        selectedAssignee = nil
        selectedMilestone = nil
        selectedPriority = nil
        debounceTask?.cancel()
    }

    /// 是否有激活的过滤条件
    var hasActiveFilters: Bool {
        !searchText.isEmpty || !selectedLabels.isEmpty
            || selectedAssignee != nil || selectedMilestone != nil
            || selectedPriority != nil
    }

    // MARK: - 过滤逻辑

    /// 过滤 CachedIssue 数组（纯内存操作）
    func filterIssues(_ issues: [CachedIssue]) -> [CachedIssue] {
        issues.filter { issue in
            matchesSearch(issue.title)
                && matchesLabels(issue.labels)
                && matchesOptionalInList(selectedAssignee, in: issue.assignees)
                && matchesOptionalValue(selectedMilestone, value: issue.milestone)
                && matchesOptionalValue(selectedPriority, value: issue.priority)
        }
    }

    /// 过滤 CachedPR 数组（仅标题搜索）
    func filterPRs(_ prs: [CachedPR]) -> [CachedPR] {
        prs.filter { matchesSearch($0.title) }
    }

    // MARK: - Private

    private func matchesSearch(_ title: String) -> Bool {
        debouncedSearchText.isEmpty
            || title.localizedCaseInsensitiveContains(debouncedSearchText)
    }

    private func matchesLabels(_ issueLabels: [String]) -> Bool {
        selectedLabels.isEmpty || selectedLabels.isSubset(of: Set(issueLabels))
    }

    private func matchesOptionalInList(_ selected: String?, in list: [String]) -> Bool {
        guard let selected else { return true }
        return list.contains(selected)
    }

    private func matchesOptionalValue(_ selected: String?, value: String?) -> Bool {
        guard let selected else { return true }
        return value == selected
    }
}
