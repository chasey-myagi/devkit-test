import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("SearchFilterViewModel")
struct SearchFilterViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self, configurations: config)
    }

    @Test @MainActor func filterByTitle() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.debouncedSearchText = "bug"

        let issue1 = CachedIssue(number: 1, title: "Fix bug in login", workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Add feature", workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func filterByTitleCaseInsensitive() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.debouncedSearchText = "BUG"

        let issue1 = CachedIssue(number: 1, title: "Fix bug in login", workspaceName: "test")
        context.insert(issue1)
        try context.save()

        let result = vm.filterIssues([issue1])
        #expect(result.count == 1)
    }

    @Test @MainActor func filterByLabel() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.selectedLabels = ["urgent"]

        let issue1 = CachedIssue(number: 1, title: "Issue A", labels: ["urgent", "bug"], workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", labels: ["feature"], workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func filterByMultipleLabels() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.selectedLabels = ["urgent", "bug"]

        let issue1 = CachedIssue(number: 1, title: "Issue A", labels: ["urgent", "bug"], workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", labels: ["urgent"], workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func filterByAssignee() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.selectedAssignee = "alice"

        let issue1 = CachedIssue(number: 1, title: "Issue A", assignees: ["alice", "bob"], workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", assignees: ["charlie"], workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func filterByMilestone() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.selectedMilestone = "v1.0"

        let issue1 = CachedIssue(number: 1, title: "Issue A", milestone: "v1.0", workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", milestone: "v2.0", workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func filterByPriority() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.selectedPriority = "P0"

        let issue1 = CachedIssue(number: 1, title: "Issue A", priority: "P0", workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", priority: "P1", workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func clearAllResetsFilters() async {
        let vm = SearchFilterViewModel()
        vm.searchText = "test"
        vm.debouncedSearchText = "test"
        vm.selectedLabels = ["bug"]
        vm.selectedAssignee = "alice"
        vm.selectedMilestone = "v1.0"
        vm.selectedPriority = "P0"

        vm.clearAll()

        #expect(vm.searchText.isEmpty)
        #expect(vm.debouncedSearchText.isEmpty)
        #expect(vm.selectedLabels.isEmpty)
        #expect(vm.selectedAssignee == nil)
        #expect(vm.selectedMilestone == nil)
        #expect(vm.selectedPriority == nil)
        #expect(vm.hasActiveFilters == false)
    }

    @Test @MainActor func noFiltersReturnsAll() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()

        let issue1 = CachedIssue(number: 1, title: "Issue A", workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Issue B", workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        try context.save()

        let result = vm.filterIssues([issue1, issue2])
        #expect(result.count == 2)
    }

    @Test @MainActor func hasActiveFiltersDetectsSearchText() async {
        let vm = SearchFilterViewModel()
        #expect(vm.hasActiveFilters == false)

        vm.searchText = "test"
        #expect(vm.hasActiveFilters == true)
    }

    @Test @MainActor func hasActiveFiltersDetectsLabels() async {
        let vm = SearchFilterViewModel()
        vm.selectedLabels = ["bug"]
        #expect(vm.hasActiveFilters == true)
    }

    @Test @MainActor func filterPRsByTitle() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.debouncedSearchText = "feat"

        let pr1 = CachedPR(number: 1, title: "feat: add search", workspaceName: "test")
        let pr2 = CachedPR(number: 2, title: "fix: login bug", workspaceName: "test")
        context.insert(pr1)
        context.insert(pr2)
        try context.save()

        let result = vm.filterPRs([pr1, pr2])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }

    @Test @MainActor func combinedFilters() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let vm = SearchFilterViewModel()
        vm.debouncedSearchText = "bug"
        vm.selectedLabels = ["urgent"]

        let issue1 = CachedIssue(number: 1, title: "Fix bug", labels: ["urgent"], workspaceName: "test")
        let issue2 = CachedIssue(number: 2, title: "Fix bug", labels: ["feature"], workspaceName: "test")
        let issue3 = CachedIssue(number: 3, title: "Add feature", labels: ["urgent"], workspaceName: "test")
        context.insert(issue1)
        context.insert(issue2)
        context.insert(issue3)
        try context.save()

        let result = vm.filterIssues([issue1, issue2, issue3])
        #expect(result.count == 1)
        #expect(result[0].number == 1)
    }
}
