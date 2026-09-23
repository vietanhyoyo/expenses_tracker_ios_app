import SwiftUI

struct DashboardBalanceCard: View {
    let balance: Decimal
    let summary: MonthlySummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            balanceHeader
            HStack(spacing: AppSpacing.medium) {
                SummaryMetric(
                    title: "Thu nhập",
                    value: summary.income,
                    icon: "arrow.down.left",
                    color: .mint
                )
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 38)
                SummaryMetric(
                    title: "Chi tiêu",
                    value: summary.expense,
                    icon: "arrow.up.right",
                    color: .orange
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var balanceHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Label("Tổng số dư", systemImage: "wallet.bifold.fill")
                .font(AppTypography.captionEmphasis)
                .foregroundStyle(.white.opacity(0.75))
            Text(AppFormatters.money(balance))
                .font(AppTypography.heroAmount)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.62)
                .lineLimit(1)
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: Decimal
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            AppIconBadge(
                icon: icon,
                color: color,
                size: 28,
                backgroundColor: .white.opacity(0.1)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.68))
                Text(AppFormatters.money(value))
                    .font(AppTypography.captionEmphasis)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
