import Foundation
import Observation

@MainActor
@Observable
final class CategoriesViewModel {
    var isLoading = false
    var categories: [ExpenseCategory] = []
    var errorMessage: String?
    var successMessage: String?
    var formDestination: CategoryFormDestination?
    var categoryToDelete: ExpenseCategory?

    private let categoryUseCases: CategoryUseCases
    private var requestVersion = 0
    private var isDeleting = false
    private var pendingDelete: (category: ExpenseCategory, replacementID: UUID)?

    init(categoryUseCases: CategoryUseCases) {
        self.categoryUseCases = categoryUseCases
    }

    func categories(of type: TransactionType) -> [ExpenseCategory] {
        categories.filter { $0.type == type }
    }

    func replacementCategories(for category: ExpenseCategory) -> [ExpenseCategory] {
        categories.filter { $0.type == category.type && $0.id != category.id }
    }

    func defaultReplacementID(for category: ExpenseCategory) -> UUID? {
        let candidates = replacementCategories(for: category)
        let preferredName = category.type == .income ? "Thu nhập khác" : "Khác"
        return candidates.first(where: { $0.name == preferredName })?.id ?? candidates.first?.id
    }

    func showAddForm() {
        formDestination = .add
    }

    func edit(_ category: ExpenseCategory) {
        guard category.isEditable else { return }
        formDestination = .edit(category)
    }

    func requestDeletion(of category: ExpenseCategory) {
        guard category.isEditable else { return }
        categoryToDelete = category
    }

    func handleFormSuccess(_ message: String) {
        successMessage = message
    }

    func load() async {
        guard !isDeleting else { return }
        isLoading = true
        requestVersion += 1
        let version = requestVersion
        defer {
            if version == requestVersion { isLoading = false }
        }
        errorMessage = nil
        do {
            let loadedCategories = try await categoryUseCases.getAll()
            guard version == requestVersion else { return }
            categories = loadedCategories
        } catch {
            guard version == requestVersion else { return }
            errorMessage = error.userMessage
        }
    }

    private func delete(_ category: ExpenseCategory, replacementID: UUID) async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        isLoading = true
        defer {
            isDeleting = false
            isLoading = false
        }
        requestVersion += 1
        let version = requestVersion
        errorMessage = nil
        do {
            try await categoryUseCases.delete(id: category.id, replacementID: replacementID)
            guard version == requestVersion else { return false }
            categories.removeAll { $0.id == category.id }
            return true
        } catch {
            guard version == requestVersion else { return false }
            errorMessage = error.userMessage
            return false
        }
    }

    func queueDelete(_ category: ExpenseCategory, replacementID: UUID) {
        pendingDelete = (category, replacementID)
    }

    func processPendingDelete() async -> Bool {
        guard let pendingDelete else { return false }
        self.pendingDelete = nil
        guard await delete(pendingDelete.category, replacementID: pendingDelete.replacementID) else {
            return false
        }
        successMessage = "Đã xoá danh mục và chuyển giao dịch thành công"
        return true
    }
}

enum CategoryFormDestination: Identifiable {
    case add
    case edit(ExpenseCategory)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let category): return category.id.uuidString
        }
    }

    var category: ExpenseCategory? {
        switch self {
        case .add: return nil
        case .edit(let category): return category
        }
    }
}
