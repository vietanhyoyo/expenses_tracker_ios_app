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
            colorHex: category.colorHex
        )
        if isEditing {
            try await categories.updateCategory(normalized)
        } else {
            try await categories.addCategory(normalized)
        }
    }

    func delete(id: UUID) async throws {
        let isUsed = try await transactions.getTransactions().contains {
            $0.categoryID == id
        }
        guard !isUsed else {
            throw DomainError.itemInUse
        }
        try await categories.deleteCategory(id: id)
    }
}
