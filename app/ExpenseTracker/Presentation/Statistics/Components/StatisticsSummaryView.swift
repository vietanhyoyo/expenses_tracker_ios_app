import SwiftUI

struct StatisticsSummaryView: View {
    let summary: MonthlySummary

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            AppMetricCard(
                title: TransactionType.income.title,
                value: AppFormatters.money(summary.income),
                icon: "arrow.down.left",
                color: TransactionType.income.color
            )
            AppMetricCard(
                title: TransactionType.expense.title,
                value: AppFormatters.money(summary.expense),
                icon: "arrow.up.right",
                color: TransactionType.expense.color
            )
        }
    }
}
