import Charts
import SwiftUI

struct DailySpendingChart: View {
    let items: [DailySpending]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            AppSectionHeader(
                title: "Xu hướng chi tiêu",
                icon: "chart.xyaxis.line"
            )
            Chart(items) { item in
                BarMark(
                    x: .value("Ngày", item.date, unit: .day),
                    y: .value("Chi tiêu", item.amount.doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.teal, AppTheme.teal.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(5)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(AppTheme.separator)
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(AppFormatters.compactMoney(number))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 220)
        }
        .appCard()
    }
}
