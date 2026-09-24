import Foundation
import Observation

@MainActor
@Observable
final class CategoriesViewModel {
    var categories: [ExpenseCategory] = []
    var errorMessage: String?

    private let useCases: CategoryUseCases
    private var requestVersion = 0
    private var isDeleting = false

    init(useCases: CategoryUseCases) {
        self.useCases = useCases
    }

    func categories(of type: TransactionType) -> [ExpenseCategory] {
        categories.filter { $0.type == type }
    }

    func load() async {
        guard !isDeleting else { return }
        requestVersion += 1
        let version = requestVersion
        errorMessage = nil
        do {
            let loadedCategories = try await useCases.getAll()
            guard version == requestVersion else { return }
            categories = loadedCategories
        } catch {
            guard version == requestVersion else { return }
            errorMessage = error.userMessage
        }
    }

    func delete(_ category: ExpenseCategory, replacementID: UUID) async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        defer { isDeleting = false }
        requestVersion += 1
        let version = requestVersion
        errorMessage = nil
        do {
            try await useCases.delete(id: category.id, replacementID: replacementID)
            guard version == requestVersion else { return false }
            categories.removeAll { $0.id == category.id }
            return true
        } catch {
            guard version == requestVersion else { return false }
            errorMessage = error.userMessage
            return false
        }
    }
}
