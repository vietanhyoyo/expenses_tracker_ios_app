import Foundation

struct TransactionDayGroup: Identifiable, Equatable {
    var id: Date { day }

    let day: Date
    let transactions: [ExpenseTransaction]
}
