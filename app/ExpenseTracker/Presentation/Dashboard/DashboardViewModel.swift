import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    var isLoading = false
    var errorMessage: String?
    var balance: Decimal = 0
    var summary = MonthlySummary(income: 0, expense: 0)
    var categorySpending: [CategorySpending] = []
    var budgetProgress: [BudgetProgress] = []
    var recentTransactions: [ExpenseTransaction] = []
    var categories: [UUID: ExpenseCategory] = [:]
    var selectedDate = Date()
    var selectedPeriod: StatisticsPeriod = .month

    private let statisticsUseCases: StatisticsUseCases
    private let dashboardUseCases: DashboardUseCases
    private let categoryUseCases: CategoryUseCases
    private let budgetUseCases: BudgetUseCases

    init(
        dashboardUseCases: DashboardUseCases,
        statisticsUseCases: StatisticsUseCases,
        categoryUseCases: CategoryUseCases,
        budgetUseCases: BudgetUseCases
    ) {
        self.dashboardUseCases = dashboardUseCases
        self.statisticsUseCases = statisticsUseCases
        self.categoryUseCases = categoryUseCases
        self.budgetUseCases = budgetUseCases
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let calendar = AppFormatters.calendar
            guard let interval = selectedPeriod.interval(
                for: selectedDate,
                calendar: calendar
            ) else {
                throw DomainError.remoteError("Không xác định được khoảng thời gian.")
            }

            let dashboardSummary = try await dashboardUseCases.summary(
                for: selectedPeriod.rawValue,
                date: selectedDate
            )
            balance = dashboardSummary.monthlyBalance
            summary = MonthlySummary(
                income: dashboardSummary.monthlyIncome,
                expense: dashboardSummary.monthlyExpense
            )
            categorySpending = try await statisticsUseCases.expenseByCategory(
                for: interval,
                calendar: calendar
            )
            budgetProgress = selectedPeriod == .month
                ? try await budgetUseCases.progress(for: selectedDate, calendar: calendar)
                : []
            recentTransactions = try await statisticsUseCases.recent(
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
