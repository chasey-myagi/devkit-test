import Testing
import Foundation
import SwiftData
@testable import DevKit

@Suite("InsightsViewModel")
struct InsightsViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Workspace.self, CachedIssue.self, CachedPR.self, configurations: config)
    }

    // MARK: - Issue Status Distribution

    @Test @MainActor func issueStatusDistribution() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp")
        context.insert(ws)

        context.insert(CachedIssue(number: 1, title: "A", projectStatus: "To Do", workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "B", projectStatus: "To Do", workspaceName: "test"))
        context.insert(CachedIssue(number: 3, title: "C", projectStatus: "In Progress", workspaceName: "test"))
        context.insert(CachedIssue(number: 4, title: "D", projectStatus: "Done", workspaceName: "test"))
        // 不属于当前 workspace 的 issue，应被忽略
        context.insert(CachedIssue(number: 5, title: "E", projectStatus: "To Do", workspaceName: "other"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let statusData = vm.issueStatusData
        #expect(statusData.count == 3)

        let todoCount = statusData.first(where: { $0.label == "To Do" })?.value
        #expect(todoCount == 2.0)

        let inProgressCount = statusData.first(where: { $0.label == "In Progress" })?.value
        #expect(inProgressCount == 1.0)

        let doneCount = statusData.first(where: { $0.label == "Done" })?.value
        #expect(doneCount == 1.0)
    }

    // MARK: - PR Column Distribution

    @Test @MainActor func prColumnDistribution() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ws = Workspace(name: "test", repoFullName: "o/r", localPath: "/tmp")
        context.insert(ws)

        context.insert(CachedPR(number: 1, title: "PR1", isDraft: true, workspaceName: "test"))
        context.insert(CachedPR(number: 2, title: "PR2", isDraft: false, reviewState: "APPROVED", checksStatus: "SUCCESS", workspaceName: "test"))
        context.insert(CachedPR(number: 3, title: "PR3", isDraft: false, reviewState: "PENDING", workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let prData = vm.prColumnData
        let draftCount = prData.first(where: { $0.label == "Draft" })?.value ?? 0
        #expect(draftCount == 1.0)

        let readyCount = prData.first(where: { $0.label == "Ready" })?.value ?? 0
        #expect(readyCount == 1.0)

        let reviewCount = prData.first(where: { $0.label == "In Review" })?.value ?? 0
        #expect(reviewCount == 1.0)
    }

    // MARK: - Label Distribution

    @Test @MainActor func labelDistribution() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(CachedIssue(number: 1, title: "A", labels: ["bug", "severity/critical"], projectStatus: "To Do", workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "B", labels: ["bug", "enhancement"], projectStatus: "In Progress", workspaceName: "test"))
        context.insert(CachedIssue(number: 3, title: "C", labels: ["enhancement"], projectStatus: "Done", workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let labelData = vm.labelDistributionData
        let bugCount = labelData.first(where: { $0.label == "bug" })?.value ?? 0
        #expect(bugCount == 2.0)

        let enhancementCount = labelData.first(where: { $0.label == "enhancement" })?.value ?? 0
        #expect(enhancementCount == 2.0)
    }

    // MARK: - Summary

    @Test @MainActor func summaryCalculation() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: .now)!

        context.insert(CachedIssue(number: 1, title: "A", projectStatus: "To Do", updatedAt: threeDaysAgo, workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "B", projectStatus: "Done", updatedAt: fiveDaysAgo, workspaceName: "test"))
        context.insert(CachedPR(number: 10, title: "PR1", workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let summary = vm.summary
        #expect(summary.totalIssues == 2)
        #expect(summary.openIssues == 1) // "To Do" + "In Progress" are open
        #expect(summary.closedIssues == 1) // "Done" is closed
        #expect(summary.totalPRs == 1)
    }

    // MARK: - Empty Workspace

    @Test @MainActor func emptyWorkspace() throws {
        let container = try makeContainer()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "nonexistent", timeRange: .week)

        #expect(vm.issueStatusData.isEmpty)
        #expect(vm.prColumnData.isEmpty)
        #expect(vm.labelDistributionData.isEmpty)
        #expect(vm.summary.totalIssues == 0)
        #expect(vm.summary.totalPRs == 0)
    }

    // MARK: - Time Range Filtering

    @Test @MainActor func timeRangeFiltering() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let twentyDaysAgo = Calendar.current.date(byAdding: .day, value: -20, to: .now)!

        context.insert(CachedIssue(number: 1, title: "Recent", projectStatus: "To Do", updatedAt: twoDaysAgo, workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "Old", projectStatus: "Done", updatedAt: twentyDaysAgo, workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)

        // 7 天范围应该只包含最近的
        vm.computeInsights(workspaceName: "test", timeRange: .week)
        #expect(vm.summary.totalIssues == 1)

        // 30 天范围应该包含两个
        vm.computeInsights(workspaceName: "test", timeRange: .month)
        #expect(vm.summary.totalIssues == 2)
    }

    // MARK: - Issue Trend Data

    @Test @MainActor func issueTrendData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let today = Calendar.current.startOfDay(for: .now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        context.insert(CachedIssue(number: 1, title: "A", projectStatus: "To Do", updatedAt: today, workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "B", projectStatus: "In Progress", updatedAt: today, workspaceName: "test"))
        context.insert(CachedIssue(number: 3, title: "C", projectStatus: "Done", updatedAt: yesterday, workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .week)

        // 趋势数据应包含按日聚合的数据点
        #expect(!vm.issueTrendData.isEmpty)
    }

    // MARK: - CSV Export Data

    @Test @MainActor func csvExportIssues() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(CachedIssue(number: 1, title: "Bug fix", labels: ["bug"], projectStatus: "To Do", assignees: ["alice"], workspaceName: "test"))
        context.insert(CachedIssue(number: 2, title: "Feature", labels: ["enhancement"], projectStatus: "Done", assignees: ["bob"], workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let csv = vm.exportIssuesCSV()
        #expect(csv.contains("Number,Title,Status,Labels,Assignees,Updated"))
        #expect(csv.contains("1,Bug fix,To Do,bug,alice"))
        #expect(csv.contains("2,Feature,Done,enhancement,bob"))
    }

    @Test @MainActor func csvExportPRs() throws {
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(CachedPR(number: 10, title: "Add feature", isDraft: false, additions: 100, deletions: 20, reviewState: "APPROVED", checksStatus: "SUCCESS", workspaceName: "test"))
        try context.save()

        let vm = InsightsViewModel(modelContainer: container)
        vm.computeInsights(workspaceName: "test", timeRange: .quarter)

        let csv = vm.exportPRsCSV()
        #expect(csv.contains("Number,Title,Column,Draft,Additions,Deletions,ReviewState,ChecksStatus,Updated"))
        #expect(csv.contains("10,Add feature,Ready,false,100,20,APPROVED,SUCCESS"))
    }
}
