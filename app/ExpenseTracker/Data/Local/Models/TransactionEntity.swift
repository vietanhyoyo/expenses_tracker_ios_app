import Foundation
import SwiftData

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var type: String
    var date: Date
    var note: String?
    var categoryID: UUID
    var accountID: UUID

    init(
        id: UUID,
        amount: Decimal,
        type: String,
        date: Date,
        note: String?,
        categoryID: UUID,
        accountID: UUID
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.categoryID = categoryID
        self.accountID = accountID
    }
}
