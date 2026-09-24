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
    var selectedDate = Date()
    var selectedPeriod: StatisticsPeriod = .month

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
            let calendar = AppFormatters.calendar
            guard let interval = selectedPeriod.interval(
                for: selectedDate,
                calendar: calendar
            ) else {
                throw DomainError.remoteError("Không xác định được khoảng thời gian.")
            }

            let dashboardSummary = try await dashboard.summary(
                for: selectedPeriod.rawValue,
                date: selectedDate
            )
            balance = dashboardSummary.monthlyBalance
            summary = MonthlySummary(
                income: dashboardSummary.monthlyIncome,
                expense: dashboardSummary.monthlyExpense
            )
            categorySpending = try await statistics.expenseByCategory(
                for: interval,
                calendar: calendar
            )
            budgetProgress = selectedPeriod == .month
                ? try await budgets.progress(for: selectedDate, calendar: calendar)
                : []
            recentTransactions = try await statistics.recent(
                limit: 5,
                in: interval,
                calendar: calendar
            )
            categories = try await categoryUseCases.getAll().keyedByID()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func movePeriod(_ offset: Int) async {
        let component: Calendar.Component = switch selectedPeriod {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
        selectedDate = AppFormatters.calendar.date(
            byAdding: component,
            value: offset,
            to: selectedDate
        ) ?? selectedDate
        await load()
    }

    func selectPeriod(_ period: StatisticsPeriod, date: Date) async {
        selectedPeriod = period
        selectedDate = date
        await load()
    }
}
