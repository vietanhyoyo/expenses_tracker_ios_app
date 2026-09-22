import Foundation

@MainActor
final class CategoryRepositoryImpl: CategoryRepository {
    private let source: CategoryLocalDataSource

    init(source: CategoryLocalDataSource) {
        self.source = source
    }

    func getCategories() async throws -> [ExpenseCategory] {
        try PersistenceErrorMapper.execute {
            try source.fetchAll().map(CategoryMapper.toDomain)
        }
    }

    func addCategory(_ category: ExpenseCategory) async throws {
        try PersistenceErrorMapper.execute {
            try source.insert(CategoryMapper.toEntity(category))
        }
    }

    func updateCategory(_ category: ExpenseCategory) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: category.id) else {
                throw DomainError.categoryNotFound
            }
            CategoryMapper.update(entity, from: category)
            try source.saveChanges()
        }
    }

    func deleteCategory(id: UUID) async throws {
        try PersistenceErrorMapper.execute {
            guard let entity = try source.fetch(id: id) else {
                throw DomainError.categoryNotFound
            }
            try source.delete(entity)
        }
    }
}
