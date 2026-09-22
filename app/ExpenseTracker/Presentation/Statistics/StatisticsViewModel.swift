import Foundation
import Observation

@MainActor
@Observable
final class StatisticsViewModel {
    var selectedMonth = Date()
    var summary = MonthlySummary(income: 0, expense: 0)
    var categorySpending: [CategorySpending] = []
    var dailySpending: [DailySpending] = []
    var dailyCashFlow: [DailyCashFlow] = []
    var errorMessage: String?

    private let statistics: StatisticsUseCases

    init(statistics: StatisticsUseCases) {
        self.statistics = statistics
    }

    var hasChartData: Bool {
        !categorySpending.isEmpty || !dailySpending.isEmpty
    }

    func load() async {
        errorMessage = nil

        do {
            summary = try await statistics.monthlySummary(for: selectedMonth)
            dailyCashFlow = try await statistics.dailyCashFlow(for: selectedMonth)
            categorySpending = try await statistics.expenseByCategory(for: selectedMonth)
            dailySpending = StatisticsUseCases.dailyExpense(from: dailyCashFlow)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func moveMonth(_ offset: Int) async {
        selectedMonth = selectedMonth.addingMonths(offset)
        await load()
    }
}
