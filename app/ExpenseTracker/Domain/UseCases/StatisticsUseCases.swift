import Foundation

@MainActor
struct StatisticsUseCases {
    let transactions: any TransactionRepository
    let categories: any CategoryRepository

    func monthlySummary(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> MonthlySummary {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return MonthlySummary(income: 0, expense: 0)
        }
        return try await summary(for: interval, calendar: calendar)
    }

    func summary(
        for interval: DateInterval,
        calendar: Calendar = .current
    ) async throws -> MonthlySummary {
        Self.summary(from: try await transactions(in: interval, calendar: calendar))
    }

    func expenseByCategory(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> [CategorySpending] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        return try await expenseByCategory(for: interval, calendar: calendar)
    }

    func expenseByCategory(
        for interval: DateInterval,
        calendar: Calendar = .current
    ) async throws -> [CategorySpending] {
        try await spendingByCategory(
            for: interval,
            type: .expense,
            calendar: calendar
        )
    }

    func spendingByCategory(
        for interval: DateInterval,
        type: TransactionType,
        calendar: Calendar = .current
    ) async throws -> [CategorySpending] {
        let allCategories = try await categories.getCategories()
        let values = try await transactions(in: interval, calendar: calendar).ofType(type)
        return Self.categorySpending(
            from: values,
            categories: allCategories,
            type: type
        )
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
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        return try await dailyCashFlow(for: interval, calendar: calendar)
    }

    func dailyCashFlow(
        for interval: DateInterval,
        calendar: Calendar = .current
    ) async throws -> [DailyCashFlow] {
        let transactionsInRange = try await transactions(in: interval, calendar: calendar)
        return Self.dailyCashFlow(from: transactionsInRange, calendar: calendar)
    }

    func spendingTrend(
        period: String,
        type: TransactionType,
        for date: Date,
        calendar: Calendar = .current
    ) async throws -> [DailySpending] {
        try await transactions.getSpendingTrend(
            period: period,
            type: type,
            date: date,
            calendar: calendar
        )
    }

    func recent(limit: Int) async throws -> [ExpenseTransaction] {
        let sortedTransactions = try await transactions.getTransactions().sorted {
            $0.date > $1.date
        }
        return Array(sortedTransactions.prefix(limit))
    }

    func recent(
        limit: Int,
        in interval: DateInterval,
        calendar: Calendar = .current
    ) async throws -> [ExpenseTransaction] {
        let values = try await transactions(in: interval, calendar: calendar)
        return Array(values.sorted { $0.date > $1.date }.prefix(limit))
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
        categorySpending(from: expenses, categories: categories, type: .expense)
    }

    static func categorySpending(
        from values: [ExpenseTransaction],
        categories: [ExpenseCategory],
        type: TransactionType
    ) -> [CategorySpending] {
        let valuesByCategory = Dictionary(grouping: values, by: \.categoryID)

        return categories
            .filter { $0.type == type }
            .compactMap { category in
                let amount = valuesByCategory[category.id]?.totalAmount ?? 0
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
        in interval: DateInterval,
        calendar: Calendar
    ) async throws -> [ExpenseTransaction] {
        guard let inclusiveEnd = calendar.date(
            byAdding: .second,
            value: -1,
            to: interval.end
        ) else {
            return []
        }
        return try await transactions.getTransactions(
            from: interval.start,
            to: inclusiveEnd,
            type: nil,
            categoryID: nil
        )
    }
}
