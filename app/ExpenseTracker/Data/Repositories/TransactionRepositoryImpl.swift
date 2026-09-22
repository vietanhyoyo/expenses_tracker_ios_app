import Foundation

@MainActor
final class TransactionRepositoryImpl: TransactionRepository {
    private let source: TransactionLocalDataSource

    init(source: TransactionLocalDataSource) {
        self.source = source
    }

    func getTransactions() async throws -> [ExpenseTransaction] {
        try PersistenceErrorMapper.execute {
            try source.fetchAll().map(TransactionMapper.toDomain)
        }
    }

    func getTransaction(id: UUID) async throws -> ExpenseTransaction? {
        try PersistenceErrorMapper.execute {
            try source.fetch(id: id).map(TransactionMapper.toDomain)
        }
    }

    func addTransaction(_ transaction: ExpenseTransaction) async throws {
        try PersistenceErrorMapper.execute {
            try source.insert(TransactionMapper.toEntity(transaction))
        }
    }

    func updateTransaction(_ transaction: ExpenseTransaction) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: transaction.id) else {
                throw DomainError.transactionNotFound
            }
            TransactionMapper.update(entity, from: transaction)
            try source.saveChanges()
        }
    }

    func deleteTransaction(id: UUID) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: id) else {
                throw DomainError.transactionNotFound
            }
            try source.delete(entity)
        }
    }
}
