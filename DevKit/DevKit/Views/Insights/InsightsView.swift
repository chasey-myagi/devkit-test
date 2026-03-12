import SwiftUI
import AppKit

/// 报表洞察主视图，展示图表与统计摘要
struct InsightsView: View {
    var workspace: Workspace
    var viewModel: InsightsViewModel

    @State private var selectedTimeRange: TimeRange = .month

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部：时间范围选择器 + 导出按钮
                HStack {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)

                    Spacer()

                    Menu("Export CSV") {
                        Button("Export Issues") {
                            exportCSV(content: viewModel.exportIssuesCSV(), filename: "issues")
                        }
                        Button("Export PRs") {
                            exportCSV(content: viewModel.exportPRsCSV(), filename: "prs")
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, 16)

                // 摘要卡片
                SummaryCardsView(summary: viewModel.summary)
                    .padding(.horizontal, 16)

                // 图表区域：2 列网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    IssueStatusChartView(data: viewModel.issueStatusData)
                    PRColumnChartView(data: viewModel.prColumnData)
                }
                .padding(.horizontal, 16)

                // 趋势图（全宽）
                IssueTrendChartView(data: viewModel.issueTrendData)
                    .padding(.horizontal, 16)

                // 标签分布（全宽）
                LabelDistributionChartView(data: viewModel.labelDistributionData)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Insights — \(workspace.name)")
        .task {
            viewModel.computeInsights(workspaceName: workspace.name, timeRange: selectedTimeRange)
        }
        .onChange(of: selectedTimeRange) { _, newRange in
            viewModel.computeInsights(workspaceName: workspace.name, timeRange: newRange)
        }
    }

    // MARK: - CSV Export

    private func exportCSV(content: String, filename: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(workspace.name)-\(filename).csv"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                // 导出失败时静默处理，后续可加日志
            }
        }
    }
}
