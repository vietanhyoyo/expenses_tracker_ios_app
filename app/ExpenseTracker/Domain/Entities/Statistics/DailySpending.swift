import Foundation

struct DailySpending: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let amount: Decimal
}

struct DailyCashFlow: Identifiable, Equatable, Sendable {
    var id: Date { date }

    let date: Date
    let income: Decimal
    let expense: Decimal

    var net: Decimal { income - expense }
}
