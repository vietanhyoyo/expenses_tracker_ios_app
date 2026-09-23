import Foundation
import SwiftData

@MainActor
final class AppContainer {
    private let modelContainer: ModelContainer
    let authUseCases: AuthUseCases
    let dashboardUseCases: DashboardUseCases
    let transactionUseCases: TransactionUseCases
    let accountUseCases: AccountUseCases
    let categoryUseCases: CategoryUseCases
    let statisticsUseCases: StatisticsUseCases
    let budgetUseCases: BudgetUseCases
    let apiClient: APIClient
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
        let localTransactionRepository = TransactionRepositoryImpl(
            source: TransactionLocalDataSource(context: context)
        )
        let localCategoryRepository = CategoryRepositoryImpl(
            source: CategoryLocalDataSource(context: context)
        )
        let localAccountRepository = AccountRepositoryImpl(
            source: AccountLocalDataSource(context: context)
        )
        let budgetRepository = BudgetRepositoryImpl(
            source: BudgetLocalDataSource(context: context)
        )

        let tokenStore = KeychainTokenStore()
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        guard let baseURL = URL(
            string: configuredURL ?? "http://localhost:3000/api/v1"
        ) else {
            throw DomainError.remoteError("Cấu hình địa chỉ API không hợp lệ.")
        }
        apiClient = APIClient(baseURL: baseURL, tokenStore: tokenStore)
        authUseCases = AuthUseCases(
            repository: AuthRepositoryImpl(api: apiClient, tokenStore: tokenStore)
        )
        dashboardUseCases = DashboardUseCases(
            repository: RemoteDashboardRepository(api: apiClient)
        )

        let accountRepository: any AccountRepository = inMemory
            ? localAccountRepository
            : RemoteAccountRepository(api: apiClient)
        let transactionRepository: any TransactionRepository
        let categoryRepository: any CategoryRepository
        if inMemory {
            transactionRepository = localTransactionRepository
            categoryRepository = localCategoryRepository
        } else {
            let metadata = RemoteMetadataStore()
            let remoteCategories = RemoteCategoryRepository(
                api: apiClient,
                metadata: metadata
            )
            let remoteTransactions = RemoteTransactionRepository(
                api: apiClient,
                accounts: accountRepository,
                metadata: metadata
            )
            categoryRepository = remoteCategories
            transactionRepository = remoteTransactions
        }

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
            categories: CategoryUseCases(
                categories: localCategoryRepository,
                transactions: localTransactionRepository
            ),
            accounts: AccountUseCases(
                accounts: localAccountRepository,
                transactions: localTransactionRepository
            ),
            includeCategories: inMemory,
            includeAccounts: inMemory
        )
    }

    func bootstrap() async {
        await defaultDataSeeder.seedIfNeeded()
    }
}
