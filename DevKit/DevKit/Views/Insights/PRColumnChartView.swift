import SwiftUI
import Charts

/// PR 看板列分布柱状图
struct PRColumnChartView: View {
    var data: [ChartDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PR Column Distribution")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "No PRs",
                    systemImage: "chart.bar",
                    description: Text("No PR data available for the selected time range.")
                )
                .frame(height: 200)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Column", point.label),
                        y: .value("Count", point.value)
                    )
                    .foregroundStyle(colorForColumn(point.label))
                    .cornerRadius(6)
                }
                .chartYAxisLabel("PRs")
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForColumn(_ column: String) -> Color {
        switch column {
        case "Draft": .gray
        case "In Review": .blue
        case "Need Fix": .red
        case "Ready": .green
        default: .secondary
        }
    }
}
