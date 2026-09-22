import Foundation

@MainActor
struct BudgetUseCases {
    /// Spending ratio from which a budget is flagged as `.warning`.
    static let warningThreshold = Decimal(8) / 10

    let budgets: any BudgetRepository
    let categories: any CategoryRepository
    let transactions: any TransactionRepository

    func getAll() async throws -> [Budget] {
        try await budgets.getBudgets()
    }

    func save(
        _ budget: Budget,
        isEditing: Bool,
        calendar: Calendar = .current
    ) async throws {
        guard budget.amount > 0 else {
            throw DomainError.invalidAmount
        }
        guard let category = try await categories.getCategories().first(where: {
            $0.id == budget.categoryID
        }) else {
            throw DomainError.categoryNotFound
        }
        guard category.type == .expense else {
            throw DomainError.invalidTransactionType
        }

        let hasDuplicate = try await budgets.getBudgets().contains {
            $0.id != budget.id
                && $0.categoryID == budget.categoryID
                && calendar.isDate($0.month, equalTo: budget.month, toGranularity: .month)
        }
        guard !hasDuplicate else {
            throw DomainError.duplicateBudget
        }

        if isEditing {
            try await budgets.updateBudget(budget)
        } else {
            try await budgets.addBudget(budget)
        }
    }

    func delete(id: UUID) async throws {
        try await budgets.deleteBudget(id: id)
    }

    func progress(
        for month: Date,
        calendar: Calendar = .current
    ) async throws -> [BudgetProgress] {
        let allCategories = try await categories.getCategories()
        let categoriesByID = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })
        let monthlyBudgets = try await budgets.getBudgets().filter {
            calendar.isDate($0.month, equalTo: month, toGranularity: .month)
        }
        let monthlyExpenses = try await transactions.getTransactions()
            .ofType(.expense)
            .inMonth(month, calendar: calendar)
        let expensesByCategory = Dictionary(grouping: monthlyExpenses, by: \.categoryID)

        return monthlyBudgets.compactMap { budget in
            guard let category = categoriesByID[budget.categoryID] else {
                return nil
            }
            let spent = expensesByCategory[budget.categoryID]?.totalAmount ?? 0
            let ratio = budget.amount > 0 ? spent / budget.amount : 0

            return BudgetProgress(
                budget: budget,
                category: category,
                spent: spent,
                ratio: ratio,
                status: Self.status(for: ratio)
            )
        }
    }

    static func status(for ratio: Decimal) -> BudgetStatus {
        if ratio >= 1 { return .exceeded }
        if ratio >= warningThreshold { return .warning }
        return .safe
    }
}
