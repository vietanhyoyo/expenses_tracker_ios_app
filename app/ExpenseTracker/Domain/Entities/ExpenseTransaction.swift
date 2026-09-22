import Foundation

struct ExpenseTransaction: Identifiable, Equatable, Sendable {
    let id: UUID
    let amount: Decimal
    let type: TransactionType
    let date: Date
    let note: String?
    let categoryID: UUID
    let accountID: UUID
}

extension Sequence where Element == ExpenseTransaction {
    var totalAmount: Decimal {
        reduce(Decimal.zero) { $0 + $1.amount }
    }

    func ofType(_ type: TransactionType) -> [ExpenseTransaction] {
        filter { $0.type == type }
    }

    func inMonth(_ month: Date, calendar: Calendar) -> [ExpenseTransaction] {
        filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
    }
}
