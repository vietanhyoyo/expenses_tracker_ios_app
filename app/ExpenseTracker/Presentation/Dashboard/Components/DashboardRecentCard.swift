import SwiftUI

struct DashboardRecentCard: View {
    let transactions: [ExpenseTransaction]
    let categories: [UUID: ExpenseCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AppSectionHeader(
                title: "Giao dịch gần đây",
                icon: "clock.fill",
                detail: "Mới nhất"
            )
            if transactions.isEmpty {
                DashboardCompactEmptyState(
                    icon: "clock.arrow.circlepath",
                    message: "Giao dịch mới sẽ xuất hiện tại đây"
                )
            } else {
                transactionRows
            }
        }
        .appCard()
    }

    private var transactionRows: some View {
        ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
            TransactionRow(
                transaction: transaction,
                category: categories[transaction.categoryID],
                account: nil
            )
            if index < transactions.count - 1 {
                Divider().padding(.leading, 54)
            }
        }
    }
}
