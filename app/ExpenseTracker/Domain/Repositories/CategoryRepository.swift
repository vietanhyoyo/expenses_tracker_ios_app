import Foundation

@MainActor
protocol CategoryRepository {
    func getCategories() async throws -> [ExpenseCategory]
    func addCategory(_ category: ExpenseCategory) async throws
    func updateCategory(_ category: ExpenseCategory) async throws
    func deleteCategory(id: UUID) async throws
}
