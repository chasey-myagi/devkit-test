import Foundation

/// 图表数据点，用于柱状图/饼图
struct ChartDataPoint: Identifiable, Sendable {
    var label: String
    var value: Double
    var color: String?

    var id: String { label }
}

/// 趋势数据点，用于折线图
struct TrendDataPoint: Identifiable, Sendable {
    var date: Date
    var value: Double
    var category: String?

    var id: Date { date }
}

/// 时间范围选择
enum TimeRange: String, CaseIterable, Sendable {
    case week
    case month
    case quarter

    var displayName: String {
        switch self {
        case .week: "7 Days"
        case .month: "30 Days"
        case .quarter: "90 Days"
        }
    }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        }
    }

    /// 从给定日期计算起始日期
    func startDate(from date: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
    }
}

/// 洞察摘要统计
struct InsightSummary: Sendable {
    var totalIssues: Int
    var openIssues: Int
    var closedIssues: Int
    var totalPRs: Int
    var openPRs: Int
    var mergedPRs: Int
    var avgIssueAge: Double  // 天数
    var avgPRAge: Double     // 天数

    /// Issue 完成率
    var issueCompletionRate: Double {
        guard totalIssues > 0 else { return 0 }
        return Double(closedIssues) / Double(totalIssues)
    }

    /// PR 合并率
    var prMergeRate: Double {
        guard totalPRs > 0 else { return 0 }
        return Double(mergedPRs) / Double(totalPRs)
    }
}
