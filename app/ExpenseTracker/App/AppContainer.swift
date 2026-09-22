import Foundation
import SwiftData

@MainActor
final class AppContainer {
    private let modelContainer: ModelContainer
    let transactionUseCases: TransactionUseCases
    let accountUseCases: AccountUseCases
    let categoryUseCases: CategoryUseCases
    let statisticsUseCases: StatisticsUseCases
    let budgetUseCases: BudgetUseCases
    private let defaultDataSeeder: DefaultDataSeeder

    init(inMemory: Bool = false) throws {
        let schema = Schema([
            TransactionEntity.self,
            CategoryEntity.self,
            AccountEntity.self,
            BudgetEntity.self
        ])
        let configuration = ModelConfiguration(
            "ExpenseTracker",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])

        let context = modelContainer.mainContext
        context.autosaveEnabled = true
        let transactionRepository = TransactionRepositoryImpl(
            source: TransactionLocalDataSource(context: context)
        )
        let categoryRepository = CategoryRepositoryImpl(
            source: CategoryLocalDataSource(context: context)
        )
        let accountRepository = AccountRepositoryImpl(
            source: AccountLocalDataSource(context: context)
        )
        let budgetRepository = BudgetRepositoryImpl(
            source: BudgetLocalDataSource(context: context)
        )

        transactionUseCases = TransactionUseCases(
            transactions: transactionRepository,
            categories: categoryRepository,
            accounts: accountRepository
        )
        accountUseCases = AccountUseCases(
            accounts: accountRepository,
            transactions: transactionRepository
        )
        categoryUseCases = CategoryUseCases(
            categories: categoryRepository,
            transactions: transactionRepository
        )
        statisticsUseCases = StatisticsUseCases(
            transactions: transactionRepository,
            categories: categoryRepository
        )
        budgetUseCases = BudgetUseCases(
            budgets: budgetRepository,
            categories: categoryRepository,
            transactions: transactionRepository
        )
        defaultDataSeeder = DefaultDataSeeder(
            categories: categoryUseCases,
            accounts: accountUseCases
        )
    }

    func bootstrap() async {
        await defaultDataSeeder.seedIfNeeded()
    }
}
