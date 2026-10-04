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

    func testCategoryFormReportsSaveOutcome() async throws {
        let container = try AppContainer(inMemory: true)
        let form = container.makeCategoryFormViewModel(category: nil)
        form.name = "  Du lịch  "

        let didSave = await form.save()
        XCTAssertTrue(didSave)
        XCTAssertEqual(form.successMessage, "Đã thêm danh mục thành công")
        let categories = try await container.categoryUseCases.getAll()
        let category = try XCTUnwrap(categories.first)
        XCTAssertEqual(category.name, "Du lịch")

        let editForm = container.makeCategoryFormViewModel(category: category)
        editForm.name = "Du lịch mới"
        let didUpdate = await editForm.save()
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(editForm.successMessage, "Đã cập nhật danh mục thành công")

        let invalidForm = container.makeCategoryFormViewModel(category: nil)
        invalidForm.name = "   "
        let didSaveInvalidName = await invalidForm.save()
        XCTAssertFalse(didSaveInvalidName)
        XCTAssertEqual(invalidForm.failureToastMessage, invalidForm.errorMessage)
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

    func testBudgetsFormDestinationKeepsSelectedMonthAndEditedBudget() throws {
        let container = try AppContainer(inMemory: true)
        let viewModel = container.makeBudgetsViewModel()
        let calendar = Calendar(identifier: .gregorian)
        let selectedMonth = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let otherMonth = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        viewModel.selectedMonth = selectedMonth

        viewModel.showAddForm()
        viewModel.selectedMonth = otherMonth
        XCTAssertNil(viewModel.formDestination?.budget)
        XCTAssertEqual(viewModel.formDestination?.month, selectedMonth)

        let category = ExpenseCategory(
            id: UUID(), name: "Du lịch", icon: "airplane", type: .expense
        )
        let budget = Budget(
            id: UUID(), categoryID: category.id, amount: 1_000_000, month: selectedMonth
        )
        let progress = BudgetProgress(
            budget: budget, category: category, spent: 0, ratio: 0, status: .safe
        )
        viewModel.edit(progress)
        XCTAssertEqual(viewModel.formDestination?.budget, budget)
        XCTAssertEqual(viewModel.formDestination?.month, selectedMonth)
    }

    func testCategoriesViewModelSplitsCategoriesByType() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let viewModel = container.makeCategoriesViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.categories(of: .expense).count, 8)
        XCTAssertEqual(viewModel.categories(of: .income).count, 4)
    }

    func testCategoriesViewModelOnlyOpensEditableCategoryActions() throws {
        let container = try AppContainer(inMemory: true)
        let viewModel = container.makeCategoriesViewModel()
        let builtInCategory = ExpenseCategory(
            id: UUID(), name: "Mặc định", icon: "star", type: .expense,
            isEditable: false
        )
        let customCategory = ExpenseCategory(
            id: UUID(), name: "Du lịch", icon: "airplane", type: .expense
        )

        viewModel.showAddForm()
        XCTAssertEqual(viewModel.formDestination?.id, "add")

        viewModel.formDestination = nil
        viewModel.edit(builtInCategory)
        viewModel.requestDeletion(of: builtInCategory)
        XCTAssertNil(viewModel.formDestination)
        XCTAssertNil(viewModel.categoryToDelete)

        viewModel.edit(customCategory)
        viewModel.requestDeletion(of: customCategory)
        XCTAssertEqual(viewModel.formDestination?.category?.id, customCategory.id)
        XCTAssertEqual(viewModel.categoryToDelete?.id, customCategory.id)
    }

    func testTransactionListCoordinatesDeletionAfterConfirmation() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let categories = try await container.categoryUseCases.getAll()
        let accounts = try await container.accountUseCases.getAll()
        let category = try XCTUnwrap(categories.first { $0.type == .expense })
        let account = try XCTUnwrap(accounts.first)
        let transaction = ExpenseTransaction(
            id: UUID(),
            amount: 100_000,
            type: .expense,
            date: Date(),
            note: nil,
            categoryID: category.id,
            accountID: account.id
        )
        try await container.transactionUseCases.save(transaction, isEditing: false)
        let viewModel = container.makeTransactionListViewModel()

        viewModel.requestDeletion(of: transaction)
        XCTAssertTrue(viewModel.isShowingDeleteConfirmation)
        viewModel.cancelDeletion()
        await viewModel.confirmDeletion()
        let transactionsAfterCancellation = try await container.transactionUseCases.getAll()
        XCTAssertEqual(transactionsAfterCancellation.count, 1)

        viewModel.requestDeletion(of: transaction)
        await viewModel.confirmDeletion()
        XCTAssertFalse(viewModel.isShowingDeleteConfirmation)
        XCTAssertEqual(viewModel.successMessage, "Đã xoá giao dịch thành công")
        let transactionsAfterDeletion = try await container.transactionUseCases.getAll()
        XCTAssertTrue(transactionsAfterDeletion.isEmpty)
    }

    func testTransactionFormSaveAndConfirmedDeletionMessages() async throws {
        let container = try AppContainer(inMemory: true)
        await container.bootstrap()
        let form = container.makeTransactionFormViewModel(transaction: nil)
        await form.load()
        form.amountText = "100.000"

        XCTAssertTrue(form.canSave)
        let didSave = await form.save()
        XCTAssertTrue(didSave)
        XCTAssertEqual(form.successMessage, "Đã thêm khoản chi thành công")

        let transactions = try await container.transactionUseCases.getAll()
        let transaction = try XCTUnwrap(transactions.first)
        let editForm = container.makeTransactionFormViewModel(transaction: transaction)
        await editForm.load()
        editForm.note = "Đã sửa"
        let didUpdate = await editForm.save()
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(editForm.successMessage, "Đã cập nhật giao dịch thành công")

        editForm.requestDeletion()
        XCTAssertTrue(editForm.isShowingDeleteConfirmation)
        editForm.cancelDeletion()
        let didDeleteAfterCancellation = await editForm.confirmDeletion()
        XCTAssertFalse(didDeleteAfterCancellation)

        editForm.requestDeletion()
        let didDelete = await editForm.confirmDeletion()
        XCTAssertTrue(didDelete)
        XCTAssertFalse(editForm.isShowingDeleteConfirmation)
        XCTAssertEqual(editForm.successMessage, "Đã xoá giao dịch thành công")
        let remainingTransactions = try await container.transactionUseCases.getAll()
        XCTAssertTrue(remainingTransactions.isEmpty)
    }

    func testDashboardPresentationState() throws {
        let container = try AppContainer(inMemory: true)
        let viewModel = container.makeDashboardViewModel(userEmail: "nguyen@example.com")

        XCTAssertEqual(viewModel.userInitials, "NG")
        XCTAssertEqual(viewModel.userDisplayName, "nguyen@example.com")

        viewModel.showTransactionForm()
        viewModel.handleFormSuccess("Đã thêm khoản chi thành công")
        XCTAssertTrue(viewModel.isShowingTransactionForm)
        XCTAssertEqual(viewModel.successMessage, "Đã thêm khoản chi thành công")

        let guestViewModel = container.makeDashboardViewModel(userEmail: nil)
        XCTAssertEqual(guestViewModel.userInitials, "TK")
        XCTAssertEqual(guestViewModel.userDisplayName, "Tài khoản của bạn")
    }
}
