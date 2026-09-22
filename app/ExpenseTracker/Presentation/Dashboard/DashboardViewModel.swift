import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var errorMessage: String?
    var balance: Decimal = 0
    var summary = MonthlySummary(income: 0, expense: 0)
    var categorySpending: [CategorySpending] = []
    var budgetProgress: [BudgetProgress] = []
    var recentTransactions: [ExpenseTransaction] = []
    var categories: [UUID: ExpenseCategory] = [:]
    var selectedMonth = Date()

    private let statistics: StatisticsUseCases
    private let accounts: AccountUseCases
    private let categoryUseCases: CategoryUseCases
    private let budgets: BudgetUseCases

    init(
        statistics: StatisticsUseCases,
        accounts: AccountUseCases,
        categories: CategoryUseCases,
        budgets: BudgetUseCases
    ) {
        self.statistics = statistics
        self.accounts = accounts
        categoryUseCases = categories
        self.budgets = budgets
    }

    func load() async {
        errorMessage = nil

        do {
            balance = try await accounts.totalBalance()
            summary = try await statistics.monthlySummary(for: selectedMonth)
            categorySpending = try await statistics.expenseByCategory(for: selectedMonth)
            budgetProgress = try await budgets.progress(for: selectedMonth)
            recentTransactions = try await statistics.recent(limit: 5)
            categories = try await categoryUseCases.getAll().keyedByID()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func moveMonth(_ offset: Int) async {
        selectedMonth = selectedMonth.addingMonths(offset)
        await load()
    }
}
