import SwiftUI

struct TransactionDaySection: View {
    let day: Date
    let transactions: [ExpenseTransaction]
    let categories: [UUID: ExpenseCategory]
    let accounts: [UUID: Account]
    let onEdit: (ExpenseTransaction) -> Void
    let onDelete: (ExpenseTransaction) -> Void

    var body: some View {
        Section {
            ForEach(transactions) { transaction in
                transactionRow(transaction)
            }
        } header: {
            sectionHeader
        }
    }

    private func transactionRow(_ transaction: ExpenseTransaction) -> some View {
        Button { onEdit(transaction) } label: {
            TransactionRow(
                transaction: transaction,
                category: categories[transaction.categoryID],
                account: accounts[transaction.accountID]
            )
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(
            top: AppSpacing.xSmall,
            leading: AppSpacing.medium,
            bottom: AppSpacing.xSmall,
            trailing: AppSpacing.medium
        ))
        .listRowBackground(AppTheme.elevatedSurface)
        .swipeActions(edge: .trailing) {
            Button("Xoá", role: .destructive) {
                onDelete(transaction)
            }
            .tint(AppTheme.coral)
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text(formattedDay)
                .font(AppTypography.captionEmphasis)
            Spacer()
            Text("\(transactions.count) giao dịch")
                .font(AppTypography.caption)
                .textCase(nil)
        }
        .foregroundStyle(.secondary)
    }

    private var formattedDay: String {
        AppFormatters.dateString(day)
    }
}
