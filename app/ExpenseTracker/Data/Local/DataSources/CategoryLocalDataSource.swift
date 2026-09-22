import Foundation
import SwiftData

typealias CategoryLocalDataSource = SwiftDataLocalDataSource<CategoryEntity>

extension SwiftDataLocalDataSource where Entity == CategoryEntity {
    convenience init(context: ModelContext) {
        self.init(context: context, sortBy: [SortDescriptor(\.name)])
    }

    func fetch(id: UUID) throws -> CategoryEntity? {
        try fetchFirst(where: #Predicate<CategoryEntity> { $0.id == id })
    }
}
