import Charts
import SwiftUI

struct CategorySpendingChart: View {
    let items: [CategorySpending]
    let transactionType: TransactionType

    private var categoryNames: [String] {
        items.map(\.category.name)
    }

    private var colors: [Color] {
        items.map(\.category.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            AppSectionHeader(
                title: "Phân bổ \(transactionType.title.lowercased()) theo danh mục",
                icon: "chart.pie.fill"
            )
            Chart(items) { item in
                SectorMark(
                    angle: .value("Số tiền", item.amount.doubleValue),
                    innerRadius: .ratio(0.62),
                    angularInset: 2.5
                )
                .foregroundStyle(by: .value("Danh mục", item.category.name))
                .cornerRadius(5)
            }
            .chartForegroundStyleScale(domain: categoryNames, range: colors)
            .chartLegend(
                position: .bottom,
                alignment: .leading,
                spacing: AppSpacing.small
            )
            .frame(height: 250)

            Divider()
            categoryRows
        }
        .appCard()
    }

    private var categoryRows: some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(items) { item in
                HStack(spacing: AppSpacing.small) {
                    AppIconBadge(
                        icon: item.category.icon,
                        color: item.category.color,
                        size: 36
                    )
                    Text(item.category.name)
                        .font(AppTypography.body)
                    Spacer()
                    Text(AppFormatters.money(item.amount))
                        .font(AppTypography.cardTitle)
                }
            }
        }
    }
}
