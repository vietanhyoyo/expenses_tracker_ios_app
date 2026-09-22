import Foundation
import SwiftData

@Model
final class BudgetEntity {
    @Attribute(.unique) var id: UUID
    var categoryID: UUID
    var amount: Decimal
    var month: Date

    init(id: UUID, categoryID: UUID, amount: Decimal, month: Date) {
        self.id = id
        self.categoryID = categoryID
        self.amount = amount
        self.month = month
    }
}
