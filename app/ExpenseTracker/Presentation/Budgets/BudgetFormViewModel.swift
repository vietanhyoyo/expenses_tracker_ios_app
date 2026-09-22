import Foundation
import Observation

@MainActor
@Observable
final class BudgetFormViewModel {
    let isEditing: Bool
    var categoryID: UUID?
    var amountText: String
    var expenseCategories: [ExpenseCategory] = []
    var isSaving = false
    var errorMessage: String?

    private let id: UUID
    private let month: Date
    private let budgets: BudgetUseCases
    private let categories: CategoryUseCases

    /// - Parameter month: Month of a new budget. An existing budget keeps its own month.
    init(
        budget: Budget?,
        month: Date,
        budgets: BudgetUseCases,
        categories: CategoryUseCases
    ) {
        id = budget?.id ?? UUID()
        isEditing = budget != nil
        self.month = budget?.month ?? month
        categoryID = budget?.categoryID
        amountText = budget.map {
            AppFormatters.vietnameseMoneyInput(from: $0.amount)
        } ?? ""
        self.budgets = budgets
        self.categories = categories
    }

    var canSave: Bool {
        categoryID != nil && (parsedAmount ?? 0) > 0 && !isSaving
    }

    func load() async {
        do {
            expenseCategories = try await categories.getAll().filter { $0.type == .expense }
            if !expenseCategories.contains(where: { $0.id == categoryID }) {
                categoryID = expenseCategories.first?.id
            }
        } catch {
            errorMessage = error.userMessage
        }
    }

    func save() async -> Bool {
        guard let categoryID, let amount = parsedAmount else {
            errorMessage = DomainError.invalidAmount.userMessage
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let budget = Budget(id: id, categoryID: categoryID, amount: amount, month: month)
        do {
            try await budgets.save(budget, isEditing: isEditing)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    private var parsedAmount: Decimal? {
        AppFormatters.decimal(from: amountText)
    }
}
