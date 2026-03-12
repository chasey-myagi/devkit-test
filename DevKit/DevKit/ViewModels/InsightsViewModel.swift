import Foundation
import SwiftData

@MainActor
@Observable
final class InsightsViewModel {
    private let modelContainer: ModelContainer

    /// Issue 状态分布数据
    private(set) var issueStatusData: [ChartDataPoint] = []
    /// PR 看板列分布数据
    private(set) var prColumnData: [ChartDataPoint] = []
    /// 标签分布数据
    private(set) var labelDistributionData: [ChartDataPoint] = []
    /// Issue 趋势数据（按日聚合）
    private(set) var issueTrendData: [TrendDataPoint] = []
    /// 统计摘要
    private(set) var summary = InsightSummary(
        totalIssues: 0, openIssues: 0, closedIssues: 0,
        totalPRs: 0, openPRs: 0, mergedPRs: 0,
        avgIssueAge: 0, avgPRAge: 0
    )

    /// 当前筛选后的 Issue 列表（用于 CSV 导出）
    private var filteredIssues: [CachedIssue] = []
    /// 当前筛选后的 PR 列表（用于 CSV 导出）
    private var filteredPRs: [CachedPR] = []

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// 根据 workspace 和时间范围计算所有洞察数据
    func computeInsights(workspaceName: String, timeRange: TimeRange) {
        let context = modelContainer.mainContext
        let startDate = timeRange.startDate()

        // 获取筛选后的 Issues
        do {
            let allIssues = try context.fetch(FetchDescriptor<CachedIssue>(
                predicate: #Predicate { $0.workspaceName == workspaceName }
            ))
            filteredIssues = allIssues.filter { $0.updatedAt >= startDate }
        } catch {
            filteredIssues = []
        }

        // 获取筛选后的 PRs
        do {
            let allPRs = try context.fetch(FetchDescriptor<CachedPR>(
                predicate: #Predicate { $0.workspaceName == workspaceName }
            ))
            filteredPRs = allPRs.filter { $0.updatedAt >= startDate }
        } catch {
            filteredPRs = []
        }

        computeIssueStatusDistribution()
        computePRColumnDistribution()
        computeLabelDistribution()
        computeIssueTrend()
        computeSummary()
    }

    // MARK: - Issue Status Distribution

    private func computeIssueStatusDistribution() {
        var counts: [String: Int] = [:]
        for issue in filteredIssues {
            counts[issue.projectStatus, default: 0] += 1
        }
        // 按预定义顺序排列
        let order = ["To Do", "In Progress", "Done"]
        var result: [ChartDataPoint] = []
        for status in order {
            if let count = counts[status] {
                result.append(ChartDataPoint(label: status, value: Double(count)))
                counts.removeValue(forKey: status)
            }
        }
        // 追加其他未知状态
        for (status, count) in counts.sorted(by: { $0.key < $1.key }) {
            result.append(ChartDataPoint(label: status, value: Double(count)))
        }
        issueStatusData = result
    }

    // MARK: - PR Column Distribution

    private func computePRColumnDistribution() {
        var counts: [String: Int] = [:]
        for pr in filteredPRs {
            counts[pr.boardColumn, default: 0] += 1
        }
        let order = ["Draft", "In Review", "Need Fix", "Ready"]
        var result: [ChartDataPoint] = []
        for column in order {
            if let count = counts[column] {
                result.append(ChartDataPoint(label: column, value: Double(count)))
                counts.removeValue(forKey: column)
            }
        }
        for (column, count) in counts.sorted(by: { $0.key < $1.key }) {
            result.append(ChartDataPoint(label: column, value: Double(count)))
        }
        prColumnData = result
    }

    // MARK: - Label Distribution

    private func computeLabelDistribution() {
        var counts: [String: Int] = [:]
        for issue in filteredIssues {
            for label in issue.labels {
                counts[label, default: 0] += 1
            }
        }
        labelDistributionData = counts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ChartDataPoint(label: $0.key, value: Double($0.value)) }
    }

    // MARK: - Issue Trend

    private func computeIssueTrend() {
        let calendar = Calendar.current
        var dailyCounts: [Date: Int] = [:]
        for issue in filteredIssues {
            let day = calendar.startOfDay(for: issue.updatedAt)
            dailyCounts[day, default: 0] += 1
        }
        issueTrendData = dailyCounts
            .sorted { $0.key < $1.key }
            .map { TrendDataPoint(date: $0.key, value: Double($0.value)) }
    }

    // MARK: - Summary

    private func computeSummary() {
        let openStatuses: Set<String> = ["To Do", "In Progress"]
        let openIssues = filteredIssues.filter { openStatuses.contains($0.projectStatus) }
        let closedIssues = filteredIssues.filter { $0.projectStatus == "Done" }

        // 计算平均 Issue 年龄（天数）
        let now = Date.now
        let issueAges = filteredIssues.map { now.timeIntervalSince($0.updatedAt) / 86400.0 }
        let avgIssueAge = issueAges.isEmpty ? 0.0 : issueAges.reduce(0, +) / Double(issueAges.count)

        // 计算平均 PR 年龄（天数）
        let prAges = filteredPRs.map { now.timeIntervalSince($0.updatedAt) / 86400.0 }
        let avgPRAge = prAges.isEmpty ? 0.0 : prAges.reduce(0, +) / Double(prAges.count)

        // PR 列分布中 "Ready" 视为已合并（本地缓存只有 open PRs，所以用 Ready 近似）
        let readyPRs = filteredPRs.filter { $0.boardColumn == "Ready" }

        summary = InsightSummary(
            totalIssues: filteredIssues.count,
            openIssues: openIssues.count,
            closedIssues: closedIssues.count,
            totalPRs: filteredPRs.count,
            openPRs: filteredPRs.count - readyPRs.count,
            mergedPRs: readyPRs.count,
            avgIssueAge: avgIssueAge,
            avgPRAge: avgPRAge
        )
    }

    // MARK: - CSV Export

    /// 导出 Issues 为 CSV 字符串
    func exportIssuesCSV() -> String {
        var lines = ["Number,Title,Status,Labels,Assignees,Updated"]
        for issue in filteredIssues.sorted(by: { $0.number < $1.number }) {
            let labelsStr = issue.labels.joined(separator: ";")
            let assigneesStr = issue.assignees.joined(separator: ";")
            let dateStr = ISO8601DateFormatter().string(from: issue.updatedAt)
            lines.append("\(issue.number),\(csvEscape(issue.title)),\(issue.projectStatus),\(labelsStr),\(assigneesStr),\(dateStr)")
        }
        return lines.joined(separator: "\n")
    }

    /// 导出 PRs 为 CSV 字符串
    func exportPRsCSV() -> String {
        var lines = ["Number,Title,Column,Draft,Additions,Deletions,ReviewState,ChecksStatus,Updated"]
        for pr in filteredPRs.sorted(by: { $0.number < $1.number }) {
            let dateStr = ISO8601DateFormatter().string(from: pr.updatedAt)
            lines.append("\(pr.number),\(csvEscape(pr.title)),\(pr.boardColumn),\(pr.isDraft),\(pr.additions),\(pr.deletions),\(pr.reviewState),\(pr.checksStatus),\(dateStr)")
        }
        return lines.joined(separator: "\n")
    }

    /// CSV 字段转义：如果包含逗号或引号，用双引号包裹
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
