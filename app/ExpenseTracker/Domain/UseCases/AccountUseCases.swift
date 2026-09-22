import Foundation

@MainActor
struct AccountUseCases {
    let accounts: any AccountRepository
    let transactions: any TransactionRepository

    func getAll() async throws -> [Account] {
        try await accounts.getAccounts()
    }

    func save(_ account: Account, isEditing: Bool) async throws {
        let name = account.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw DomainError.invalidName
        }
        guard account.initialBalance >= 0 else {
            throw DomainError.invalidAmount
        }

        let normalized = Account(
            id: account.id,
            name: name,
            initialBalance: account.initialBalance
        )
        if isEditing {
            try await accounts.updateAccount(normalized)
        } else {
            try await accounts.addAccount(normalized)
        }
    }

    func delete(id: UUID) async throws {
        let isUsed = try await transactions.getTransactions().contains {
            $0.accountID == id
        }
        guard !isUsed else {
            throw DomainError.itemInUse
        }
        try await accounts.deleteAccount(id: id)
    }

    /// Current balance of every account, keyed by account ID.
    /// Transactions are fetched once regardless of the number of accounts.
    func balances() async throws -> [UUID: Decimal] {
        let allAccounts = try await accounts.getAccounts()
        let allTransactions = try await transactions.getTransactions()
        let transactionsByAccount = Dictionary(grouping: allTransactions, by: \.accountID)

        return Dictionary(uniqueKeysWithValues: allAccounts.map { account in
            (
                account.id,
                Self.calculateBalance(
                    account: account,
                    transactions: transactionsByAccount[account.id] ?? []
                )
            )
        })
    }

    func totalBalance() async throws -> Decimal {
        try await balances().values.reduce(0, +)
    }

    static func calculateBalance(
        account: Account,
        transactions: [ExpenseTransaction]
    ) -> Decimal {
        let ownTransactions = transactions.filter { $0.accountID == account.id }
        return account.initialBalance
            + ownTransactions.ofType(.income).totalAmount
            - ownTransactions.ofType(.expense).totalAmount
    }
}
