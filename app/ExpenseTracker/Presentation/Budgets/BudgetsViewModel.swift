import Foundation
import Observation

@MainActor
@Observable
final class BudgetsViewModel {
    var isLoading = false
    var selectedMonth = Date()
    var progress: [BudgetProgress] = []
    var errorMessage: String?

    private let budgetUseCases: BudgetUseCases

    init(budgetUseCases: BudgetUseCases) {
        self.budgetUseCases = budgetUseCases
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            progress = try await budgetUseCases.progress(for: selectedMonth)
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

    func delete(_ progress: BudgetProgress) async {
        do {
            try await budgetUseCases.delete(id: progress.budget.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
