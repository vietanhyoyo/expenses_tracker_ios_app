enum TransactionMapper {
    static func toDomain(_ entity: TransactionEntity) throws -> ExpenseTransaction {
        guard let type = TransactionType(rawValue: entity.type) else {
            throw DomainError.invalidTransactionType
        }

        return ExpenseTransaction(
            id: entity.id,
            amount: entity.amount,
            type: type,
            date: entity.date,
            note: entity.note,
            categoryID: entity.categoryID,
            accountID: entity.accountID
        )
    }

    static func toEntity(_ transaction: ExpenseTransaction) -> TransactionEntity {
        TransactionEntity(
            id: transaction.id,
            amount: transaction.amount,
            type: transaction.type.rawValue,
            date: transaction.date,
            note: transaction.note,
            categoryID: transaction.categoryID,
            accountID: transaction.accountID
        )
    }

    static func update(
        _ entity: TransactionEntity,
        from transaction: ExpenseTransaction
    ) {
        entity.amount = transaction.amount
        entity.type = transaction.type.rawValue
        entity.date = transaction.date
        entity.note = transaction.note
        entity.categoryID = transaction.categoryID
        entity.accountID = transaction.accountID
    }
}
