import Foundation

@MainActor
struct CategoryUseCases {
    let categories: any CategoryRepository
    let transactions: any TransactionRepository

    func getAll() async throws -> [ExpenseCategory] {
        try await categories.getCategories()
    }

    func save(_ category: ExpenseCategory, isEditing: Bool) async throws {
        let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw DomainError.invalidName
        }

        let normalized = ExpenseCategory(
            id: category.id,
            name: name,
            icon: category.icon,
            type: category.type,
            colorHex: category.colorHex,
            isEditable: category.isEditable
        )
        if isEditing {
            try await categories.updateCategory(normalized)
        } else {
            try await categories.addCategory(normalized)
        }
    }

    func delete(id: UUID, replacementID: UUID) async throws {
        let availableCategories = try await categories.getCategories()
        guard let category = availableCategories.first(where: { $0.id == id }),
              category.isEditable else {
            throw DomainError.categoryNotEditable
        }
        guard let replacement = availableCategories.first(where: { $0.id == replacementID }),
              replacement.id != category.id,
              replacement.type == category.type else {
            throw DomainError.invalidCategoryReplacement
        }
        try await categories.deleteCategory(id: id, replacementID: replacementID)
    }
}
