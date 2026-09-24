import Foundation
import Observation

@MainActor
@Observable
final class AccountsViewModel {
    var isLoading = false
    var accounts: [Account] = []
    var balances: [UUID: Decimal] = [:]
    var errorMessage: String?

    private let useCases: AccountUseCases

    init(useCases: AccountUseCases) {
        self.useCases = useCases
    }

    func balance(for account: Account) -> Decimal {
        balances[account.id] ?? account.initialBalance
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            accounts = try await useCases.getAll()
            balances = try await useCases.balances()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ account: Account) async {
        do {
            try await useCases.delete(id: account.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
