import Foundation

struct Budget: Identifiable, Equatable, Sendable {
    let id: UUID
    let categoryID: UUID
    let amount: Decimal
    let month: Date
}
