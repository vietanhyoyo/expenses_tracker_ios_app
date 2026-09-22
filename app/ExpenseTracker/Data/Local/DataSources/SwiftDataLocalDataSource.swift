import Foundation
import SwiftData

/// Thin wrapper around `ModelContext` shared by every entity-specific data source.
/// Entity-specific queries live in constrained extensions (see `AccountLocalDataSource`).
@MainActor
final class SwiftDataLocalDataSource<Entity: PersistentModel> {
    private let context: ModelContext
    private let defaultSort: [SortDescriptor<Entity>]

    init(context: ModelContext, sortBy defaultSort: [SortDescriptor<Entity>]) {
        self.context = context
        self.defaultSort = defaultSort
    }

    func fetchAll() throws -> [Entity] {
        try context.fetch(FetchDescriptor<Entity>(sortBy: defaultSort))
    }

    func fetchFirst(where predicate: Predicate<Entity>) throws -> Entity? {
        var descriptor = FetchDescriptor<Entity>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func insert(_ entity: Entity) throws {
        context.insert(entity)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }

    func delete(_ entity: Entity) throws {
        context.delete(entity)
        try context.save()
    }
}
