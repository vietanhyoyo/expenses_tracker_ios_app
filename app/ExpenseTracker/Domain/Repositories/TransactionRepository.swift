import Foundation

@MainActor
protocol TransactionRepository {
    func getTransactions() async throws -> [ExpenseTransaction]
    func getTransactions(
        from startDate: Date?,
        to endDate: Date?,
        type: TransactionType?,
        categoryID: UUID?
    ) async throws -> [ExpenseTransaction]
    func getSpendingTrend(
        period: String,
        type: TransactionType,
        date: Date,
        calendar: Calendar
    ) async throws -> [DailySpending]
    func getTransaction(id: UUID) async throws -> ExpenseTransaction?
    func addTransaction(_ transaction: ExpenseTransaction) async throws
    func updateTransaction(_ transaction: ExpenseTransaction) async throws
    func deleteTransaction(id: UUID) async throws
}

extension TransactionRepository {
    /// Allows local repositories to keep their existing storage behavior while
    /// remote repositories can push supported filters to the API.
    func getTransactions(
        from startDate: Date?,
        to endDate: Date?,
        type: TransactionType?,
        categoryID: UUID?
    ) async throws -> [ExpenseTransaction] {
        let calendar = Calendar.current
        let startDay = startDate.map { calendar.startOfDay(for: $0) }
        let endDay = endDate.map { calendar.startOfDay(for: $0) }

        return try await getTransactions().filter { transaction in
            (startDay == nil || transaction.date >= startDay!)
                && (endDay == nil || transaction.date < calendar.date(byAdding: .day, value: 1, to: endDay!)!)
                && (type == nil || transaction.type == type)
                && (categoryID == nil || transaction.categoryID == categoryID)
        }
    }

    func getSpendingTrend(
        period: String,
        type: TransactionType,
        date: Date,
        calendar: Calendar
    ) async throws -> [DailySpending] {
        let interval: DateInterval?
        switch period {
        case "week":
            var weekCalendar = calendar
            weekCalendar.firstWeekday = 2
            weekCalendar.minimumDaysInFirstWeek = 4
            interval = weekCalendar.dateInterval(of: .weekOfYear, for: date)
        case "year":
            interval = calendar.dateInterval(of: .year, for: date)
        default:
            interval = calendar.dateInterval(of: .month, for: date)
        }
        guard let interval,
              let inclusiveEnd = calendar.date(byAdding: .second, value: -1, to: interval.end)
        else { return [] }

        let values = try await getTransactions(
            from: interval.start,
            to: inclusiveEnd,
            type: type,
            categoryID: nil
        )
        let grouped = Dictionary(grouping: values) { transaction -> Date in
            if period == "year" {
                return calendar.dateInterval(of: .month, for: transaction.date)?.start
                    ?? calendar.startOfDay(for: transaction.date)
            }
            return calendar.startOfDay(for: transaction.date)
        }
        return grouped.map { date, transactions in
            DailySpending(date: date, amount: transactions.totalAmount)
        }.sorted { $0.date < $1.date }
    }
}
