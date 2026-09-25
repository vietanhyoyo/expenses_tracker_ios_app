import SwiftUI

struct DashboardBalanceCard: View {
    let balance: Decimal
    let summary: MonthlySummary
    let period: StatisticsPeriod

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

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
                    .frame(width: 1, height: isPad ? 48 : 38)
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
            Label(period.balanceTitle, systemImage: AppSymbols.accountFilled)
                .font(
                    isPad
                        ? .system(size: 17, weight: .semibold, design: .rounded)
                        : AppTypography.captionEmphasis
                )
                .foregroundStyle(.white.opacity(0.75))
            Text(AppFormatters.money(balance))
                .font(
                    isPad
                        ? .system(size: 50, weight: .bold, design: .rounded)
                        : AppTypography.heroAmount
                )
                .foregroundStyle(.white)
                .minimumScaleFactor(0.62)
                .lineLimit(1)
        }
    }
}

private extension StatisticsPeriod {
    var balanceTitle: String {
        switch self {
        case .week: "Số dư tuần"
        case .month: "Số dư tháng"
        case .year: "Số dư năm"
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: Decimal
    let icon: String
    let color: Color

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            AppIconBadge(
                icon: icon,
                color: color,
                size: isPad ? 34 : 28,
                backgroundColor: .white.opacity(0.1)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(
                        isPad
                            ? .system(size: 16, weight: .medium, design: .rounded)
                            : AppTypography.caption
                    )
                    .foregroundStyle(.white.opacity(0.68))
                Text(AppFormatters.money(value))
                    .font(
                        isPad
                            ? .system(size: 19, weight: .semibold, design: .rounded)
                            : AppTypography.captionEmphasis
                    )
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
