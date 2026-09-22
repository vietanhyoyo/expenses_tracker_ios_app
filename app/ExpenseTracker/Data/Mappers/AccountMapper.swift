enum AccountMapper {
    static func toDomain(_ entity: AccountEntity) -> Account {
        Account(
            id: entity.id,
            name: entity.name,
            initialBalance: entity.initialBalance
        )
    }

    static func toEntity(_ account: Account) -> AccountEntity {
        AccountEntity(
            id: account.id,
            name: account.name,
            initialBalance: account.initialBalance
        )
    }

    static func update(_ entity: AccountEntity, from account: Account) {
        entity.name = account.name
        entity.initialBalance = account.initialBalance
    }
}
