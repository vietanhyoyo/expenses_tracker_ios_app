import Foundation

struct MonthlySummary: Equatable, Sendable {
    let income: Decimal
    let expense: Decimal

    var net: Decimal { income - expense }
}
