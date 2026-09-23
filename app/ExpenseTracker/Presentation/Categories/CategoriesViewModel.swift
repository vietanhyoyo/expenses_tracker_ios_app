import Foundation
import Observation

@MainActor
@Observable
final class CategoriesViewModel {
    var categories: [ExpenseCategory] = []
    var errorMessage: String?

    private let useCases: CategoryUseCases

    init(useCases: CategoryUseCases) {
        self.useCases = useCases
    }

    func categories(of type: TransactionType) -> [ExpenseCategory] {
        categories.filter { $0.type == type }
    }

    func load() async {
        errorMessage = nil
        do {
            categories = try await useCases.getAll()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ category: ExpenseCategory) async -> Bool {
        errorMessage = nil
        do {
            try await useCases.delete(id: category.id)
            await load()
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
