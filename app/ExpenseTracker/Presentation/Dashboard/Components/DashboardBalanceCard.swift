import SwiftUI

struct DashboardBalanceCard: View {
    let balance: Decimal
    let summary: MonthlySummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
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
        .padding(AppSpacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.heroGradient,
            in: RoundedRectangle(cornerRadius: AppRadius.xLarge, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 150, height: 150)
                .offset(x: 45, y: -75)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xLarge, style: .continuous))
        .shadow(color: AppTheme.navy.opacity(0.2), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }

    private var balanceHeader: some View {
        HStack(alignment: .top) {
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
            Spacer(minLength: AppSpacing.small)
            AppIconBadge(
                icon: "waveform.path.ecg",
                color: .white.opacity(0.72),
                size: 44,
                backgroundColor: .white.opacity(0.11),
                iconScale: 0.5
            )
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
