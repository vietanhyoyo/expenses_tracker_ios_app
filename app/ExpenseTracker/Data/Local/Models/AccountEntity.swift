import Foundation
import SwiftData

@Model
final class AccountEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var initialBalance: Decimal

    init(id: UUID, name: String, initialBalance: Decimal) {
        self.id = id
        self.name = name
        self.initialBalance = initialBalance
    }
}
