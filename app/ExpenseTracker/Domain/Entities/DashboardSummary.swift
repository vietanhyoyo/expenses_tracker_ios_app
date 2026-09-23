import Foundation

struct DashboardSummary: Equatable, Sendable {
    let month: String
    let totalBalance: Decimal
    let monthlyIncome: Decimal
    let monthlyExpense: Decimal
    let monthlyBalance: Decimal
}
