import Foundation

/// Lightweight repositories used only by tests and SwiftUI previews.
/// Production always uses the remote API implementations.
@MainActor
final class InMemoryAccountRepository: AccountRepository {
    private var items: [Account] = []

    func getAccounts() async throws -> [Account] {
        items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func addAccount(_ account: Account) async throws {
        items.append(account)
    }

    func updateAccount(_ account: Account) async throws {
        guard let index = items.firstIndex(where: { $0.id == account.id }) else {
            throw DomainError.accountNotFound
        }
        items[index] = account
    }

    func deleteAccount(id: UUID) async throws {
        guard items.contains(where: { $0.id == id }) else {
            throw DomainError.accountNotFound
        }
        items.removeAll { $0.id == id }
    }
}

@MainActor
final class InMemoryCategoryRepository: CategoryRepository {
    private var items: [ExpenseCategory] = []

    func getCategories() async throws -> [ExpenseCategory] {
        items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func addCategory(_ category: ExpenseCategory) async throws {
        items.append(category)
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        guard let index = items.firstIndex(where: { $0.id == category.id }) else {
            throw DomainError.categoryNotFound
        }
        items[index] = category
    }

    func deleteCategory(id: UUID) async throws {
        guard items.contains(where: { $0.id == id }) else {
            throw DomainError.categoryNotFound
        }
        items.removeAll { $0.id == id }
    }
}

@MainActor
final class InMemoryTransactionRepository: TransactionRepository {
    private var items: [ExpenseTransaction] = []

    func getTransactions() async throws -> [ExpenseTransaction] {
        items.sorted { $0.date > $1.date }
    }

    func getTransaction(id: UUID) async throws -> ExpenseTransaction? {
        items.first { $0.id == id }
    }

    func addTransaction(_ transaction: ExpenseTransaction) async throws {
        items.append(transaction)
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        guard let index = items.firstIndex(where: { $0.id == transaction.id }) else {
            throw DomainError.transactionNotFound
        }
        items[index] = transaction
    }

    func deleteTransaction(id: UUID) async throws {
        guard items.contains(where: { $0.id == id }) else {
            throw DomainError.transactionNotFound
        }
        items.removeAll { $0.id == id }
    }
}
