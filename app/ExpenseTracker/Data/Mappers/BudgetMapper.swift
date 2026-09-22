enum BudgetMapper {
    static func toDomain(_ entity: BudgetEntity) -> Budget {
        Budget(
            id: entity.id,
            categoryID: entity.categoryID,
            amount: entity.amount,
            month: entity.month
        )
    }

    static func toEntity(_ budget: Budget) -> BudgetEntity {
        BudgetEntity(
            id: budget.id,
            categoryID: budget.categoryID,
            amount: budget.amount,
            month: budget.month
        )
    }

    static func update(_ entity: BudgetEntity, from budget: Budget) {
        entity.categoryID = budget.categoryID
        entity.amount = budget.amount
        entity.month = budget.month
    }
}
