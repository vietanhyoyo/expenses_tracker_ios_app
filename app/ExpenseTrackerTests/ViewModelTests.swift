import XCTest
@testable import ExpenseTracker

@MainActor
final class ViewModelTests: XCTestCase {
    func testAccountFormSavesTrimmedNameAndParsedBalance() async throws {
        let container = try AppContainer(inMemory: true)
        let form = container.makeAccountFormViewModel(account: nil)
        form.name = "  Ngân hàng "
        form.initialBalanceText = "1.500.000"

        XCTAssertTrue(form.canSave)
        let didSave = await form.save()

        XCTAssertTrue(didSave)
        let accounts = try await container.accountUseCases.getAll()
        XCTAssertEqual(accounts.map(\.name), ["Ngân hàng"])
        XCTAssertEqual(accounts.first?.initialBalance, 1_500_000)
    }

    func testAccountFormCannotSaveBlankName() throws {
        let container = try AppContainer(inMemory: true)
        let form = container.makeAccountFormViewModel(account: nil)
        form.name = "   "

        XCTAssertFalse(form.canSave)
    }

    func testCategoryFormUsesTypeColorOnlyForNewCategory() throws {
        let container = try AppContainer(inMemory: true)
        let newForm = container.makeCategoryFormViewModel(category: nil)
        newForm.type = .income
        newForm.typeChanged()
        XCTAssertEqual(newForm.colorHex, ExpenseCategory.defaultColorHex(for: .income))

        let existing = ExpenseCategory(id: UUID(), name: "Du lịch", icon: "airplane", type: .expense, colorHex: "#7C3AED")
        let editForm = container.makeCategoryFormViewModel(category: existing)
        editForm.type = .income
        editForm.typeChanged()
        XCTAssertEqual(editForm.colorHex, "#7C3AED")
    }

    func testBudgetFormLoadsExpenseCategoriesAndSelectsFirst() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let form = container.makeBudgetFormViewModel(budget: nil, month: Date())

        await form.load()

        XCTAssertFalse(form.expenseCategories.isEmpty)
        XCTAssertTrue(form.expenseCategories.allSatisfy { $0.type == .expense })
        XCTAssertEqual(form.categoryID, form.expenseCategories.first?.id)
    }

    func testCategoriesViewModelSplitsCategoriesByType() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let viewModel = container.makeCategoriesViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.categories(of: .expense).count, 8)
        XCTAssertEqual(viewModel.categories(of: .income).count, 4)
    }
}
