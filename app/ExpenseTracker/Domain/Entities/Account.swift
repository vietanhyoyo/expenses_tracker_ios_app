import Foundation

struct Account: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let initialBalance: Decimal
}
