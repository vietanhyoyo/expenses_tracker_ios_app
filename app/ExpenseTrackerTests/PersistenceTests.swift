import XCTest
@testable import ExpenseTracker

@MainActor
final class PersistenceTests: XCTestCase {
    func testCategoryCustomColorRoundTrip() async throws {
        let container = try AppContainer(inMemory: true)
        let category = ExpenseCategory(
            id: UUID(),
            name: "Du lịch",
            icon: "airplane",
            type: .expense,
            colorHex: "#7C3AED"
        )

        try await container.categoryUseCases.save(category, isEditing: false)

        let categories = try await container.categoryUseCases.getAll()
        let stored = try XCTUnwrap(categories.first { $0.id == category.id })
        XCTAssertEqual(stored.colorHex, "#7C3AED")
    }

    func testBootstrapIsIdempotent() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let categoryCount = try await container.categoryUseCases.getAll().count
        let accountCount = try await container.accountUseCases.getAll().count
        await container.bootstrap()
        let categoryCountAfterSecondBootstrap = try await container.categoryUseCases.getAll().count
        let accountCountAfterSecondBootstrap = try await container.accountUseCases.getAll().count
        XCTAssertEqual(categoryCountAfterSecondBootstrap, categoryCount)
        XCTAssertEqual(accountCountAfterSecondBootstrap, accountCount)
        XCTAssertEqual(categoryCount, 12)
        XCTAssertEqual(accountCount, 1)
    }

    func testTransactionRoundTrip() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let categories = try await container.categoryUseCases.getAll()
        let accounts = try await container.accountUseCases.getAll()
        let category = try XCTUnwrap(categories.first { $0.type == .expense })
        let account = try XCTUnwrap(accounts.first)
        let value = ExpenseTransaction(id: UUID(), amount: 125_000, type: .expense, date: Date(), note: "Bữa trưa", categoryID: category.id, accountID: account.id)
        try await container.transactionUseCases.save(value, isEditing: false)
        let stored = try await container.transactionUseCases.get(id: value.id)
        XCTAssertEqual(stored, value)
        try await container.transactionUseCases.delete(id: value.id)
        let deleted = try await container.transactionUseCases.get(id: value.id)
        XCTAssertNil(deleted)
    }
}
