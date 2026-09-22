import SwiftUI

struct DashboardSpendingCard: View {
    let items: [CategorySpending]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            AppSectionHeader(
                title: "Chi tiêu theo danh mục",
                icon: "chart.pie.fill"
            )
            if items.isEmpty {
                DashboardCompactEmptyState(
                    icon: "chart.pie",
                    message: "Chưa có chi tiêu trong tháng"
                )
            } else {
                spendingRows
            }
        }
        .appCard()
    }

    private var spendingRows: some View {
        let visibleItems = Array(items.prefix(4))

        return VStack(spacing: AppSpacing.small) {
            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: AppSpacing.small) {
                    AppIconBadge(icon: item.category.icon, color: item.category.color, size: 38)
                    Text(item.category.name)
                        .font(AppTypography.body)
                    Spacer()
                    Text(AppFormatters.money(item.amount))
                        .font(AppTypography.cardTitle)
                }
                if index < visibleItems.count - 1 {
                    Divider().padding(.leading, 50)
                }
            }
        }
    }
}
