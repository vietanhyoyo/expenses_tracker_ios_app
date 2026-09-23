import Charts
import SwiftUI

struct DailySpendingChart: View {
    let items: [DailySpending]
    let period: StatisticsPeriod
    let transactionType: TransactionType

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            AppSectionHeader(
                title: "Xu hướng \(transactionType.title.lowercased())",
                icon: "chart.xyaxis.line"
            )
            Chart(items) { item in
                BarMark(
                    x: .value(
                        period == .year ? "Tháng" : "Ngày",
                        item.date,
                        unit: period == .year ? .month : .day
                    ),
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
                AxisMarks(
                    values: .stride(
                        by: period == .year ? .month : .day,
                        count: period == .year || period == .week ? 1 : 5
                    )
                ) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(vietnameseAxisLabel(for: date))
                        }
                    }
                }
            }
            .frame(height: 220)
        }
        .appCard()
    }

    private func vietnameseAxisLabel(for date: Date) -> String {
        let calendar = AppFormatters.calendar
        switch period {
        case .year:
            return String(calendar.component(.month, from: date))
        case .week:
            let weekday = calendar.component(.weekday, from: date)
            let labels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
            return labels.indices.contains(weekday - 1) ? labels[weekday - 1] : ""
        case .month:
            return String(calendar.component(.day, from: date))
        }
    }
}
