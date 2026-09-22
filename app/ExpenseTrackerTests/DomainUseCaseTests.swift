import XCTest
@testable import ExpenseTracker

@MainActor
final class DomainUseCaseTests: XCTestCase {
    func testAccountBalanceUsesInitialIncomeAndExpenses() {
        let account = Account(id: UUID(), name: "Ví", initialBalance: 1_000_000)
        let category = UUID()
        let values = [
            ExpenseTransaction(id: UUID(), amount: 500_000, type: .income, date: Date(), note: nil, categoryID: category, accountID: account.id),
            ExpenseTransaction(id: UUID(), amount: 200_000, type: .expense, date: Date(), note: nil, categoryID: category, accountID: account.id)
        ]
        XCTAssertEqual(AccountUseCases.calculateBalance(account: account, transactions: values), 1_300_000)
    }

    func testMonthlySummarySeparatesIncomeAndExpense() {
        let values = [
            transaction(amount: 2_000_000, type: .income),
            transaction(amount: 300_000, type: .expense),
            transaction(amount: 200_000, type: .expense)
        ]
        XCTAssertEqual(StatisticsUseCases.summary(from: values), MonthlySummary(income: 2_000_000, expense: 500_000))
    }

    func testDailyCashFlowGroupsIncomeAndExpenseByDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let firstDay = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 9,
            day: 14
        )))
        let secondDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: firstDay))
        let values = [
            transaction(amount: 2_000_000, type: .income, date: firstDay),
            transaction(amount: 300_000, type: .expense, date: firstDay),
            transaction(amount: 50_000, type: .expense, date: secondDay)
        ]

        XCTAssertEqual(
            StatisticsUseCases.dailyCashFlow(from: values, calendar: calendar),
            [
                DailyCashFlow(date: firstDay, income: 2_000_000, expense: 300_000),
                DailyCashFlow(date: secondDay, income: 0, expense: 50_000)
            ]
        )
    }

    func testBudgetThresholds() {
        XCTAssertEqual(BudgetUseCases.status(for: 0.79), .safe)
        XCTAssertEqual(BudgetUseCases.status(for: 0.8), .warning)
        XCTAssertEqual(BudgetUseCases.status(for: 1), .exceeded)
    }

    func testVietnameseMoneyInputUsesDotGroupingSeparator() {
        XCTAssertEqual(AppFormatters.vietnameseMoneyInput("1"), "1")
        XCTAssertEqual(AppFormatters.vietnameseMoneyInput("1234"), "1.234")
        XCTAssertEqual(AppFormatters.vietnameseMoneyInput("1234567"), "1.234.567")
        XCTAssertEqual(AppFormatters.vietnameseMoneyInput("001234"), "1.234")
        XCTAssertEqual(AppFormatters.vietnameseMoneyInput(""), "")
    }

    func testFormattedVietnameseMoneyInputRemainsParsable() {
        let formatted = AppFormatters.vietnameseMoneyInput("1234567")
        XCTAssertEqual(AppFormatters.decimal(from: formatted), 1_234_567)
    }

    func testCompactMoneyUsesVietnameseDecimalSeparator() {
        XCTAssertEqual(AppFormatters.compactMoney(20_200_000), "20,2tr")
        XCTAssertEqual(AppFormatters.compactMoney(20_000_000), "20tr")
        XCTAssertEqual(AppFormatters.compactMoney(300_000), "300k")
    }

    func testAddTransactionRejectsNonPositiveAmount() async {
        let transactionRepository = MockTransactionRepository()
        let categoryRepository = MockCategoryRepository()
        let accountRepository = MockAccountRepository()
        let useCases = TransactionUseCases(transactions: transactionRepository, categories: categoryRepository, accounts: accountRepository)
        do {
            try await useCases.save(transaction(amount: 0, type: .expense), isEditing: false)
            XCTFail("Expected invalidAmount")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidAmount)
        }
    }

    func testAddTransactionRejectsMismatchedCategory() async {
        let category = ExpenseCategory(id: UUID(), name: "Lương", icon: "banknote", type: .income)
        let account = Account(id: UUID(), name: "Ví", initialBalance: 0)
        let useCases = TransactionUseCases(
            transactions: MockTransactionRepository(),
            categories: MockCategoryRepository(items: [category]),
            accounts: MockAccountRepository(items: [account])
        )
        let value = ExpenseTransaction(id: UUID(), amount: 10, type: .expense, date: Date(), note: nil, categoryID: category.id, accountID: account.id)
        do {
            try await useCases.save(value, isEditing: false)
            XCTFail("Expected invalidTransactionType")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidTransactionType)
        }
    }

    func testAccountBalancesAreKeyedByAccount() async throws {
        let wallet = Account(id: UUID(), name: "Ví", initialBalance: 100_000)
        let bank = Account(id: UUID(), name: "Ngân hàng", initialBalance: 0)
        let transactions = MockTransactionRepository()
        transactions.items = [
            ExpenseTransaction(id: UUID(), amount: 40_000, type: .expense, date: Date(), note: nil, categoryID: UUID(), accountID: wallet.id),
            ExpenseTransaction(id: UUID(), amount: 500_000, type: .income, date: Date(), note: nil, categoryID: UUID(), accountID: bank.id)
        ]
        let useCases = AccountUseCases(accounts: MockAccountRepository(items: [wallet, bank]), transactions: transactions)

        let balances = try await useCases.balances()
        let total = try await useCases.totalBalance()

        XCTAssertEqual(balances, [wallet.id: 60_000, bank.id: 500_000])
        XCTAssertEqual(total, 560_000)
    }

    func testSaveCategoryRejectsBlankNameAndTrimsName() async throws {
        let repository = MockCategoryRepository()
        let useCases = CategoryUseCases(categories: repository, transactions: MockTransactionRepository())

        do {
            try await useCases.save(ExpenseCategory(id: UUID(), name: "   ", icon: "star", type: .expense), isEditing: false)
            XCTFail("Expected invalidName")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidName)
        }

        try await useCases.save(ExpenseCategory(id: UUID(), name: "  Du lịch ", icon: "airplane", type: .expense), isEditing: false)
        XCTAssertEqual(repository.items.map(\.name), ["Du lịch"])
    }

    func testSaveBudgetRejectsUnknownCategory() async {
        let useCases = BudgetUseCases(
            budgets: MockBudgetRepository(),
            categories: MockCategoryRepository(),
            transactions: MockTransactionRepository()
        )
        let budget = Budget(id: UUID(), categoryID: UUID(), amount: 1_000_000, month: Date())

        do {
            try await useCases.save(budget, isEditing: false)
            XCTFail("Expected categoryNotFound")
        } catch {
            XCTAssertEqual(error as? DomainError, .categoryNotFound)
        }
    }

    func testExpenseByCategoryGroupsAndSortsDescending() {
        let food = ExpenseCategory(id: UUID(), name: "Ăn uống", icon: "fork.knife", type: .expense)
        let transport = ExpenseCategory(id: UUID(), name: "Di chuyển", icon: "car.fill", type: .expense)
        let salary = ExpenseCategory(id: UUID(), name: "Lương", icon: "banknote.fill", type: .income)
        let expenses = [
            ExpenseTransaction(id: UUID(), amount: 50_000, type: .expense, date: Date(), note: nil, categoryID: food.id, accountID: UUID()),
            ExpenseTransaction(id: UUID(), amount: 30_000, type: .expense, date: Date(), note: nil, categoryID: food.id, accountID: UUID()),
            ExpenseTransaction(id: UUID(), amount: 120_000, type: .expense, date: Date(), note: nil, categoryID: transport.id, accountID: UUID())
        ]

        XCTAssertEqual(
            StatisticsUseCases.expenseByCategory(from: expenses, categories: [food, transport, salary]),
            [
                CategorySpending(category: transport, amount: 120_000),
                CategorySpending(category: food, amount: 80_000)
            ]
        )
    }

    func testDailyExpenseSkipsDaysWithoutExpense() {
        let day = Date(timeIntervalSince1970: 0)
        let nextDay = day.addingTimeInterval(86_400)
        let cashFlow = [
            DailyCashFlow(date: day, income: 1_000, expense: 0),
            DailyCashFlow(date: nextDay, income: 0, expense: 2_000)
        ]

        XCTAssertEqual(
            StatisticsUseCases.dailyExpense(from: cashFlow),
            [DailySpending(date: nextDay, amount: 2_000)]
        )
    }

    private func transaction(
        amount: Decimal,
        type: TransactionType,
        date: Date = Date()
    ) -> ExpenseTransaction {
        ExpenseTransaction(id: UUID(), amount: amount, type: type, date: date, note: nil, categoryID: UUID(), accountID: UUID())
    }
}

@MainActor
private final class MockBudgetRepository: BudgetRepository {
    var items: [Budget] = []
    func getBudgets() async throws -> [Budget] { items }
    func addBudget(_ budget: Budget) async throws { items.append(budget) }
    func updateBudget(_ budget: Budget) async throws { if let index = items.firstIndex(where: { $0.id == budget.id }) { items[index] = budget } }
    func deleteBudget(id: UUID) async throws { items.removeAll { $0.id == id } }
}

@MainActor
private final class MockTransactionRepository: TransactionRepository {
    var items: [ExpenseTransaction] = []
    func getTransactions() async throws -> [ExpenseTransaction] { items }
    func getTransaction(id: UUID) async throws -> ExpenseTransaction? { items.first { $0.id == id } }
    func addTransaction(_ transaction: ExpenseTransaction) async throws { items.append(transaction) }
    func updateTransaction(_ transaction: ExpenseTransaction) async throws { if let index = items.firstIndex(where: { $0.id == transaction.id }) { items[index] = transaction } }
    func deleteTransaction(id: UUID) async throws { items.removeAll { $0.id == id } }
}

@MainActor
private final class MockCategoryRepository: CategoryRepository {
    var items: [ExpenseCategory]
    init(items: [ExpenseCategory] = []) { self.items = items }
    func getCategories() async throws -> [ExpenseCategory] { items }
    func addCategory(_ category: ExpenseCategory) async throws { items.append(category) }
    func updateCategory(_ category: ExpenseCategory) async throws { if let index = items.firstIndex(where: { $0.id == category.id }) { items[index] = category } }
    func deleteCategory(id: UUID) async throws { items.removeAll { $0.id == id } }
}

@MainActor
private final class MockAccountRepository: AccountRepository {
    var items: [Account]
    init(items: [Account] = []) { self.items = items }
    func getAccounts() async throws -> [Account] { items }
    func addAccount(_ account: Account) async throws { items.append(account) }
    func updateAccount(_ account: Account) async throws { if let index = items.firstIndex(where: { $0.id == account.id }) { items[index] = account } }
    func deleteAccount(id: UUID) async throws { items.removeAll { $0.id == id } }
}
