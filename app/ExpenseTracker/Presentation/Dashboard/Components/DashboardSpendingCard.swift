import SwiftUI

struct DashboardSpendingCard: View {
    let items: [CategorySpending]

    var body: some View {
        DashboardSectionCard(
            title: "Chi tiêu theo danh mục",
            icon: "chart.pie.fill"
        ) {
            if items.isEmpty {
                DashboardCompactEmptyState(
                    icon: "chart.pie",
                    message: "Chưa có chi tiêu trong tháng"
                )
            } else {
                spendingRows
            }
        }
    }

    private var spendingRows: some View {
        return VStack(spacing: AppSpacing.small) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: AppSpacing.small) {
                    AppIconBadge(icon: item.category.icon, color: item.category.color, size: 38)
                    Text(item.category.name)
                        .font(AppTypography.body)
                    Spacer()
                    Text(AppFormatters.money(item.amount))
                        .font(AppTypography.cardTitle)
                }
                if index < items.count - 1 {
                    Divider().padding(.leading, 50)
                }
            }
        }
    }
}
