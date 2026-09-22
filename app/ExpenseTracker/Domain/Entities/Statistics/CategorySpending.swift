import Foundation

struct CategorySpending: Identifiable, Equatable, Sendable {
    var id: UUID { category.id }

    let category: ExpenseCategory
    let amount: Decimal
}
