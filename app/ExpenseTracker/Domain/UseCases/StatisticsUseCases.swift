import Foundation

@MainActor
struct StatisticsUseCases {
    let transactions: any TransactionRepository
    let categories: any CategoryRepository

    func monthlySummary(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> MonthlySummary {
        let transactionsInMonth = try await transactions(in: month, calendar: calendar)
        return Self.summary(from: transactionsInMonth)
    }

    func expenseByCategory(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> [CategorySpending] {
        let allCategories = try await categories.getCategories()
        let expenses = try await transactions(in: month, calendar: calendar).ofType(.expense)
        return Self.expenseByCategory(from: expenses, categories: allCategories)
    }

    func dailyExpense(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> [DailySpending] {
        let cashFlow = try await dailyCashFlow(for: month, calendar: calendar)
        return Self.dailyExpense(from: cashFlow)
    }

    func dailyCashFlow(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> [DailyCashFlow] {
        let transactionsInMonth = try await transactions(in: month, calendar: calendar)
        return Self.dailyCashFlow(from: transactionsInMonth, calendar: calendar)
    }

    func recent(limit: Int) async throws -> [ExpenseTransaction] {
        let sortedTransactions = try await transactions.getTransactions().sorted {
            $0.date > $1.date
        }
        return Array(sortedTransactions.prefix(limit))
    }

    static func summary(from transactions: [ExpenseTransaction]) -> MonthlySummary {
        MonthlySummary(
            income: transactions.ofType(.income).totalAmount,
            expense: transactions.ofType(.expense).totalAmount
        )
    }

    static func expenseByCategory(
        from expenses: [ExpenseTransaction],
        categories: [ExpenseCategory]
    ) -> [CategorySpending] {
        let expensesByCategory = Dictionary(grouping: expenses, by: \.categoryID)

        return categories
            .filter { $0.type == .expense }
            .compactMap { category in
                let amount = expensesByCategory[category.id]?.totalAmount ?? 0
                return amount > 0
                    ? CategorySpending(category: category, amount: amount)
                    : nil
            }
            .sorted { $0.amount > $1.amount }
    }

    static func dailyCashFlow(
        from transactions: [ExpenseTransaction],
        calendar: Calendar = .current
    ) -> [DailyCashFlow] {
        Dictionary(grouping: transactions) {
            calendar.startOfDay(for: $0.date)
        }
        .map { day, transactions in
            let summary = Self.summary(from: transactions)
            return DailyCashFlow(
                date: day,
                income: summary.income,
                expense: summary.expense
            )
        }
        .sorted { $0.date < $1.date }
    }

    static func dailyExpense(from cashFlow: [DailyCashFlow]) -> [DailySpending] {
        cashFlow
            .filter { $0.expense > 0 }
            .map { DailySpending(date: $0.date, amount: $0.expense) }
    }

    private func transactions(
        in month: Date,
        calendar: Calendar
    ) async throws -> [ExpenseTransaction] {
        try await transactions.getTransactions().inMonth(month, calendar: calendar)
    }
}
