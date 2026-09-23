import Foundation

@MainActor
final class DefaultDataSeeder {
    private let categories: CategoryUseCases
    private let accounts: AccountUseCases
    private let includeCategories: Bool
    private let includeAccounts: Bool

    init(
        categories: CategoryUseCases,
        accounts: AccountUseCases,
        includeCategories: Bool,
        includeAccounts: Bool
    ) {
        self.categories = categories
        self.accounts = accounts
        self.includeCategories = includeCategories
        self.includeAccounts = includeAccounts
    }

    func seedIfNeeded() async {
        do {
            try await seedCategoriesIfNeeded()
            try await seedAccountIfNeeded()
        } catch {
            // Feature screens surface persistence failures. Seeding remains retryable.
        }
    }

    private func seedCategoriesIfNeeded() async throws {
        guard includeCategories else { return }
        let existingNames = Set(try await categories.getAll().map(\.name))
        for category in Self.defaultCategories where !existingNames.contains(category.name) {
            try await categories.save(category, isEditing: false)
        }
    }

    private func seedAccountIfNeeded() async throws {
        guard includeAccounts else { return }
        guard try await accounts.getAll().isEmpty else { return }

        let cashAccount = Account(
            id: UUID(),
            name: "Tiền mặt",
            initialBalance: 0
        )
        try await accounts.save(cashAccount, isEditing: false)
    }

    /// Colors come from `ExpenseCategory.defaultPalette`, keyed by name.
    private static let defaultCategories: [ExpenseCategory] = [
        ExpenseCategory(id: UUID(), name: "Ăn uống", icon: "fork.knife", type: .expense),
        ExpenseCategory(id: UUID(), name: "Di chuyển", icon: "car.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Mua sắm", icon: "bag.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Giải trí", icon: "gamecontroller.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Hoá đơn", icon: "doc.text.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Sức khoẻ", icon: "cross.case.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Giáo dục", icon: "book.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Khác", icon: "square.grid.2x2.fill", type: .expense),
        ExpenseCategory(id: UUID(), name: "Lương", icon: "banknote.fill", type: .income),
        ExpenseCategory(id: UUID(), name: "Thưởng", icon: "gift.fill", type: .income),
        ExpenseCategory(id: UUID(), name: "Đầu tư", icon: "chart.line.uptrend.xyaxis", type: .income),
        ExpenseCategory(id: UUID(), name: "Thu nhập khác", icon: "plus.circle.fill", type: .income)
    ]
}
