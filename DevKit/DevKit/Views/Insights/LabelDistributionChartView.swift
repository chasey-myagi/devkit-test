import SwiftUI
import Charts

/// 标签分布横向柱状图（Top 10）
struct LabelDistributionChartView: View {
    var data: [ChartDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Labels")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "No Labels",
                    systemImage: "tag",
                    description: Text("No label data available for the selected time range.")
                )
                .frame(height: 200)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Count", point.value),
                        y: .value("Label", point.label)
                    )
                    .foregroundStyle(.tint)
                    .cornerRadius(6)
                }
                .chartXAxisLabel("Issues")
                .frame(height: max(CGFloat(data.count) * 30, 100))
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
