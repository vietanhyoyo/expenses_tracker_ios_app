import SwiftUI

struct DashboardRecentCard: View {
    let transactions: [ExpenseTransaction]
    let categories: [UUID: ExpenseCategory]
    let onShowAll: () -> Void

    var body: some View {
        DashboardSectionCard(
            title: "Giao dịch gần đây",
            icon: "clock.fill",
            detail: "Mới nhất",
            actionTitle: "Xem thêm",
            action: onShowAll
        ) {
            if transactions.isEmpty {
                DashboardCompactEmptyState(
                    icon: "clock.arrow.circlepath",
                    message: "Giao dịch mới sẽ xuất hiện tại đây"
                )
            } else {
                transactionRows
            }
        }
    }

    private var transactionRows: some View {
        let visibleTransactions = Array(transactions.prefix(5))

        return ForEach(Array(visibleTransactions.enumerated()), id: \.element.id) { index, transaction in
            TransactionRow(
                transaction: transaction,
                category: categories[transaction.categoryID],
                account: nil
            )
            if index < visibleTransactions.count - 1 {
                Divider().padding(.leading, 54)
            }
        }
    }
}
