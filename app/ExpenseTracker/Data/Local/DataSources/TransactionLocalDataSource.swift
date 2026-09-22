import Foundation
import SwiftData

typealias TransactionLocalDataSource = SwiftDataLocalDataSource<TransactionEntity>

extension SwiftDataLocalDataSource where Entity == TransactionEntity {
    convenience init(context: ModelContext) {
        self.init(context: context, sortBy: [SortDescriptor(\.date, order: .reverse)])
    }

    func fetch(id: UUID) throws -> TransactionEntity? {
        try fetchFirst(where: #Predicate<TransactionEntity> { $0.id == id })
    }
}
