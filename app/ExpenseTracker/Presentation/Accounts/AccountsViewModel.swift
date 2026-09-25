import Foundation
import Observation

@MainActor
@Observable
final class AccountsViewModel {
    var isLoading = false
    var accounts: [Account] = []
    var balances: [UUID: Decimal] = [:]
    var errorMessage: String?

    private let accountUseCases: AccountUseCases

    init(accountUseCases: AccountUseCases) {
        self.accountUseCases = accountUseCases
    }

    func balance(for account: Account) -> Decimal {
        balances[account.id] ?? account.initialBalance
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            accounts = try await accountUseCases.getAll()
            balances = try await accountUseCases.balances()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ account: Account) async {
        do {
            try await accountUseCases.delete(id: account.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
