import Foundation
import SwiftData

typealias AccountLocalDataSource = SwiftDataLocalDataSource<AccountEntity>

extension SwiftDataLocalDataSource where Entity == AccountEntity {
    convenience init(context: ModelContext) {
        self.init(context: context, sortBy: [SortDescriptor(\.name)])
    }

    func fetch(id: UUID) throws -> AccountEntity? {
        try fetchFirst(where: #Predicate<AccountEntity> { $0.id == id })
    }
}
