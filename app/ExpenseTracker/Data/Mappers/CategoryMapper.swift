enum CategoryMapper {
    static func toDomain(_ entity: CategoryEntity) throws -> ExpenseCategory {
        guard let type = TransactionType(rawValue: entity.type) else {
            throw DomainError.invalidTransactionType
        }
        return ExpenseCategory(
            id: entity.id,
            name: entity.name,
            icon: entity.icon,
            type: type,
            colorHex: entity.colorHex
        )
    }

    static func toEntity(_ category: ExpenseCategory) -> CategoryEntity {
        CategoryEntity(
            id: category.id,
            name: category.name,
            icon: category.icon,
            type: category.type.rawValue,
            colorHex: category.colorHex
        )
    }

    static func update(_ entity: CategoryEntity, from category: ExpenseCategory) {
        entity.name = category.name
        entity.icon = category.icon
        entity.type = category.type.rawValue
        entity.colorHex = category.colorHex
    }
}
