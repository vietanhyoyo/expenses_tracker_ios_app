import Foundation

@MainActor
protocol BudgetRepository {
    func getBudgets() async throws -> [Budget]
    func addBudget(_ budget: Budget) async throws
    func updateBudget(_ budget: Budget) async throws
    func deleteBudget(id: UUID) async throws
}
