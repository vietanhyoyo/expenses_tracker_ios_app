import Foundation

@MainActor
struct TransactionUseCases {
    let transactions: any TransactionRepository
    let categories: any CategoryRepository
    let accounts: any AccountRepository

    func getAll() async throws -> [ExpenseTransaction] {
        try await transactions.getTransactions()
    }

    func getAll(
        from startDate: Date?,
        to endDate: Date?,
        type: TransactionType?,
        categoryID: UUID?
    ) async throws -> [ExpenseTransaction] {
        try await transactions.getTransactions(
            from: startDate,
            to: endDate,
            type: type,
            categoryID: categoryID
        )
    }

    func get(id: UUID) async throws -> ExpenseTransaction? {
        try await transactions.getTransaction(id: id)
    }

    func save(_ transaction: ExpenseTransaction, isEditing: Bool) async throws {
        guard transaction.amount > 0 else {
            throw DomainError.invalidAmount
        }
        guard let category = try await categories.getCategories().first(where: {
            $0.id == transaction.categoryID
        }) else {
            throw DomainError.categoryNotFound
        }
        guard category.type == transaction.type else {
            throw DomainError.invalidTransactionType
        }
        guard try await accounts.getAccounts().contains(where: {
            $0.id == transaction.accountID
        }) else {
            throw DomainError.accountNotFound
        }

        if isEditing {
            try await transactions.updateTransaction(transaction)
        } else {
            try await transactions.addTransaction(transaction)
        }
    }

    func delete(id: UUID) async throws {
        try await transactions.deleteTransaction(id: id)
    }
}
