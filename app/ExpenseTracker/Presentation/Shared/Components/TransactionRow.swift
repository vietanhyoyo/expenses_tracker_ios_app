import SwiftUI

struct TransactionRow: View {
    let transaction: ExpenseTransaction
    let category: ExpenseCategory?
    let account: Account?

    private var amountColor: Color {
        transaction.type.color
    }

    private var iconColor: Color {
        category?.color ?? amountColor
    }

    private var title: String {
        if let note = transaction.note, !note.isEmpty {
            return note
        }
        return category?.name ?? "Giao dịch"
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            AppIconBadge(
                icon: category?.icon ?? "questionmark",
                color: iconColor
            )
            VStack(alignment: .leading, spacing: AppSpacing.xxxSmall) {
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text([category?.name, account?.name].compactMap { $0 }.joined(separator: " • "))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xSmall)
            VStack(alignment: .trailing, spacing: AppSpacing.xxxSmall) {
                Text(signedAmount)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(AppFormatters.shortDate.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, AppSpacing.xxxSmall)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var signedAmount: String {
        let sign = transaction.type == .income ? "+" : "−"
        return sign + AppFormatters.money(transaction.amount)
    }
}
