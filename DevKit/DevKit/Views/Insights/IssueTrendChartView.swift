import SwiftUI
import Charts

/// Issue 活跃趋势折线图（按日聚合）
struct IssueTrendChartView: View {
    var data: [TrendDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issue Activity Trend")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView(
                    "No Trend Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("No trend data available for the selected time range.")
                )
                .frame(height: 200)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Issues", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Issues", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.opacity(0.1))

                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Issues", point.value)
                    )
                    .foregroundStyle(.blue)
                }
                .chartYAxisLabel("Updated Issues")
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
