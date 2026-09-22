import Foundation

@MainActor
protocol TransactionRepository {
    func getTransactions() async throws -> [ExpenseTransaction]
    func getTransaction(id: UUID) async throws -> ExpenseTransaction?
    func addTransaction(_ transaction: ExpenseTransaction) async throws
    func updateTransaction(_ transaction: ExpenseTransaction) async throws
    func deleteTransaction(id: UUID) async throws
}
