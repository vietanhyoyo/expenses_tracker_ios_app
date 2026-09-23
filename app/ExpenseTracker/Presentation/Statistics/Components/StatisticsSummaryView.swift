import SwiftUI

struct StatisticsSummaryView: View {
    let summary: MonthlySummary
    let selectedType: TransactionType
    let onSelect: (TransactionType) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            metricCard(
                for: .income,
                value: summary.income,
                icon: "arrow.down.left"
            )
            metricCard(
                for: .expense,
                value: summary.expense,
                icon: "arrow.up.right"
            )
        }
    }

    private func metricCard(
        for type: TransactionType,
        value: Decimal,
        icon: String
    ) -> some View {
        Button {
            onSelect(type)
        } label: {
            AppMetricCard(
                title: type.title,
                value: AppFormatters.money(value),
                icon: icon,
                color: type.color
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .stroke(
                        selectedType == type ? type.color : Color.clear,
                        lineWidth: selectedType == type ? 2 : 0
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.title)
        .accessibilityValue(selectedType == type ? "Đang chọn" : "")
    }
}
