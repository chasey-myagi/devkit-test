import Testing
import Foundation
@testable import DevKit

@Suite("InsightModels")
struct InsightModelsTests {

    // MARK: - ChartDataPoint

    @Test func chartDataPointIdentifiable() {
        let point = ChartDataPoint(label: "To Do", value: 5)
        #expect(point.id == "To Do")
        #expect(point.label == "To Do")
        #expect(point.value == 5.0)
    }

    @Test func chartDataPointWithDoubleValue() {
        let point = ChartDataPoint(label: "Ratio", value: 3.14)
        #expect(point.value == 3.14)
    }

    @Test func chartDataPointDefaultColor() {
        let point = ChartDataPoint(label: "Test", value: 1)
        #expect(point.color == nil)
    }

    @Test func chartDataPointWithColor() {
        let point = ChartDataPoint(label: "Red", value: 2, color: "red")
        #expect(point.color == "red")
    }

    // MARK: - TrendDataPoint

    @Test func trendDataPointIdentifiable() {
        let date = Date(timeIntervalSince1970: 1000000)
        let point = TrendDataPoint(date: date, value: 10)
        #expect(point.date == date)
        #expect(point.value == 10.0)
        #expect(point.id == date)
    }

    @Test func trendDataPointWithCategory() {
        let date = Date.now
        let point = TrendDataPoint(date: date, value: 5, category: "Issues")
        #expect(point.category == "Issues")
    }

    // MARK: - TimeRange

    @Test func timeRangeAllCases() {
        let cases = TimeRange.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.week))
        #expect(cases.contains(.month))
        #expect(cases.contains(.quarter))
    }

    @Test func timeRangeDisplayName() {
        #expect(TimeRange.week.displayName == "7 Days")
        #expect(TimeRange.month.displayName == "30 Days")
        #expect(TimeRange.quarter.displayName == "90 Days")
    }

    @Test func timeRangeDays() {
        #expect(TimeRange.week.days == 7)
        #expect(TimeRange.month.days == 30)
        #expect(TimeRange.quarter.days == 90)
    }

    @Test func timeRangeStartDate() {
        let now = Date.now
        let weekStart = TimeRange.week.startDate(from: now)
        // 7 天前，允许 1 秒误差
        let expectedInterval = TimeInterval(-7 * 86400)
        #expect(abs(weekStart.timeIntervalSince(now) - expectedInterval) < 1.0)
    }

    // MARK: - InsightSummary

    @Test func insightSummaryInit() {
        let summary = InsightSummary(
            totalIssues: 10,
            openIssues: 7,
            closedIssues: 3,
            totalPRs: 5,
            openPRs: 3,
            mergedPRs: 2,
            avgIssueAge: 4.5,
            avgPRAge: 2.0
        )
        #expect(summary.totalIssues == 10)
        #expect(summary.openIssues == 7)
        #expect(summary.closedIssues == 3)
        #expect(summary.totalPRs == 5)
        #expect(summary.openPRs == 3)
        #expect(summary.mergedPRs == 2)
        #expect(summary.avgIssueAge == 4.5)
        #expect(summary.avgPRAge == 2.0)
    }

    @Test func insightSummaryCompletionRate() {
        let summary = InsightSummary(
            totalIssues: 10,
            openIssues: 6,
            closedIssues: 4,
            totalPRs: 0,
            openPRs: 0,
            mergedPRs: 0,
            avgIssueAge: 0,
            avgPRAge: 0
        )
        #expect(summary.issueCompletionRate == 0.4)
    }

    @Test func insightSummaryCompletionRateZeroTotal() {
        let summary = InsightSummary(
            totalIssues: 0,
            openIssues: 0,
            closedIssues: 0,
            totalPRs: 0,
            openPRs: 0,
            mergedPRs: 0,
            avgIssueAge: 0,
            avgPRAge: 0
        )
        #expect(summary.issueCompletionRate == 0)
    }

    @Test func insightSummaryPRMergeRate() {
        let summary = InsightSummary(
            totalIssues: 0,
            openIssues: 0,
            closedIssues: 0,
            totalPRs: 8,
            openPRs: 3,
            mergedPRs: 5,
            avgIssueAge: 0,
            avgPRAge: 0
        )
        #expect(summary.prMergeRate == 0.625)
    }
}
