import Foundation

@MainActor
final class BudgetRepositoryImpl: BudgetRepository {
    private let source: BudgetLocalDataSource

    init(source: BudgetLocalDataSource) {
        self.source = source
    }

    func getBudgets() async throws -> [Budget] {
        try PersistenceErrorMapper.execute {
            try source.fetchAll().map(BudgetMapper.toDomain)
        }
    }

    func addBudget(_ budget: Budget) async throws {
        try PersistenceErrorMapper.execute {
            try source.insert(BudgetMapper.toEntity(budget))
        }
    }

    func updateBudget(_ budget: Budget) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: budget.id) else {
                throw DomainError.budgetNotFound
            }
            BudgetMapper.update(entity, from: budget)
            try source.saveChanges()
        }
    }

    func deleteBudget(id: UUID) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: id) else {
                throw DomainError.budgetNotFound
            }
            try source.delete(entity)
        }
    }
}
