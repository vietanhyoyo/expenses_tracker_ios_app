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
        do {
            categories = try await useCases.getAll()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ category: ExpenseCategory) async {
        do {
            try await useCases.delete(id: category.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
