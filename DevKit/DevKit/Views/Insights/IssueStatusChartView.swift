import SwiftUI
import Charts

/// Issue 状态分布柱状图
struct IssueStatusChartView: View {
    var data: [ChartDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issue Status Distribution")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "No Issues",
                    systemImage: "chart.bar",
                    description: Text("No issue data available for the selected time range.")
                )
                .frame(height: 200)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Status", point.label),
                        y: .value("Count", point.value)
                    )
                    .foregroundStyle(colorForStatus(point.label))
                    .cornerRadius(6)
                }
                .chartYAxisLabel("Issues")
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "To Do": .blue
        case "In Progress": .orange
        case "Done": .green
        default: .gray
        }
    }
}
