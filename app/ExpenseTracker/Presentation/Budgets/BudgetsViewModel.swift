import Foundation
import Observation

@MainActor
@Observable
final class BudgetsViewModel {
    var isLoading = false
    var selectedMonth = Date()
    var progress: [BudgetProgress] = []
    var errorMessage: String?
    var formDestination: BudgetFormDestination?

    private let budgetUseCases: BudgetUseCases

    init(budgetUseCases: BudgetUseCases) {
        self.budgetUseCases = budgetUseCases
    }

    func showAddForm() {
        formDestination = .add(month: selectedMonth)
    }

    func edit(_ progress: BudgetProgress) {
        formDestination = .edit(budget: progress.budget)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
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

enum BudgetFormDestination: Identifiable {
    case add(month: Date)
    case edit(budget: Budget)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let budget): return budget.id.uuidString
        }
    }

    var budget: Budget? {
        switch self {
        case .add: return nil
        case .edit(let budget): return budget
        }
    }

    var month: Date {
        switch self {
        case .add(let month): return month
        case .edit(let budget): return budget.month
        }
    }
}
