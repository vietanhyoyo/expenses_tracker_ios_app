import Foundation
import SwiftData

typealias BudgetLocalDataSource = SwiftDataLocalDataSource<BudgetEntity>

extension SwiftDataLocalDataSource where Entity == BudgetEntity {
    convenience init(context: ModelContext) {
        self.init(context: context, sortBy: [SortDescriptor(\.month, order: .reverse)])
    }

    func fetch(id: UUID) throws -> BudgetEntity? {
        try fetchFirst(where: #Predicate<BudgetEntity> { $0.id == id })
    }
}
