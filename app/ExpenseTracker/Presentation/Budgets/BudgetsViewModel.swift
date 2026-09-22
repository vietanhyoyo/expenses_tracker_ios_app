import Foundation
import Observation

@MainActor
@Observable
final class BudgetsViewModel {
    var selectedMonth = Date()
    var progress: [BudgetProgress] = []
    var errorMessage: String?

    private let budgets: BudgetUseCases

    init(budgets: BudgetUseCases) {
        self.budgets = budgets
    }

    func load() async {
        do {
            progress = try await budgets.progress(for: selectedMonth)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func moveMonth(_ offset: Int) async {
        selectedMonth = selectedMonth.addingMonths(offset)
        await load()
    }

    func delete(_ progress: BudgetProgress) async {
        do {
            try await budgets.delete(id: progress.budget.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
