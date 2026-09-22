import Foundation

@MainActor
final class AccountRepositoryImpl: AccountRepository {
    private let source: AccountLocalDataSource

    init(source: AccountLocalDataSource) {
        self.source = source
    }

    func getAccounts() async throws -> [Account] {
        try PersistenceErrorMapper.execute {
            try source.fetchAll().map(AccountMapper.toDomain)
        }
    }

    func addAccount(_ account: Account) async throws {
        try PersistenceErrorMapper.execute {
            try source.insert(AccountMapper.toEntity(account))
        }
    }

    func updateAccount(_ account: Account) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: account.id) else {
                throw DomainError.accountNotFound
            }
            AccountMapper.update(entity, from: account)
            try source.saveChanges()
        }
    }

    func deleteAccount(id: UUID) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: id) else {
                throw DomainError.accountNotFound
            }
            try source.delete(entity)
        }
    }
}
