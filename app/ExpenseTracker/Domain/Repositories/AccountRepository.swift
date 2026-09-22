import Foundation

@MainActor
protocol AccountRepository {
    func getAccounts() async throws -> [Account]
    func addAccount(_ account: Account) async throws
    func updateAccount(_ account: Account) async throws
    func deleteAccount(id: UUID) async throws
}
