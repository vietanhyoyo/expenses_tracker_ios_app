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
    private let dashboard: DashboardUseCases
    private let categoryUseCases: CategoryUseCases
    private let budgets: BudgetUseCases

    init(
        dashboard: DashboardUseCases,
        statistics: StatisticsUseCases,
        categories: CategoryUseCases,
        budgets: BudgetUseCases
    ) {
        self.dashboard = dashboard
        self.statistics = statistics
        categoryUseCases = categories
        self.budgets = budgets
    }

    func load() async {
        errorMessage = nil

        do {
            let dashboardSummary = try await dashboard.summary(for: selectedMonth)
            balance = dashboardSummary.totalBalance
            summary = MonthlySummary(
                income: dashboardSummary.monthlyIncome,
                expense: dashboardSummary.monthlyExpense
            )
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

    func selectMonth(_ month: Date) async {
        selectedMonth = month
        await load()
    }
}
