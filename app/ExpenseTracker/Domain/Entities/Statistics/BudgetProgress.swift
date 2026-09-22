import Foundation

enum BudgetStatus: Equatable, Sendable {
    case safe
    case warning
    case exceeded
}

struct BudgetProgress: Identifiable, Equatable, Sendable {
    var id: UUID { budget.id }

    let budget: Budget
    let category: ExpenseCategory
    let spent: Decimal
    let ratio: Decimal
    let status: BudgetStatus
}
