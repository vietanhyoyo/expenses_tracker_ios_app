import Foundation

@MainActor
final class AppContainer {
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
        let tokenStore = KeychainTokenStore()
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        guard let baseURL = URL(
            string: configuredURL ?? "http://localhost:3000/api/v1"
        ) else {
            throw DomainError.remoteError("Cấu hình địa chỉ API không hợp lệ.")
        }
        apiClient = APIClient(baseURL: baseURL, tokenStore: tokenStore)
        let budgetRepository: any BudgetRepository
        if inMemory {
            budgetRepository = InMemoryBudgetRepository()
        } else {
            budgetRepository = BudgetRepositoryImpl(api: apiClient)
        }
        authUseCases = AuthUseCases(
            repository: AuthRepositoryImpl(api: apiClient, tokenStore: tokenStore)
        )
        dashboardUseCases = DashboardUseCases(
            repository: DashboardRepositoryImpl(api: apiClient)
        )

        let accountRepository: any AccountRepository = inMemory
            ? InMemoryAccountRepository()
            : AccountRepositoryImpl(api: apiClient)
        let transactionRepository: any TransactionRepository
        let categoryRepository: any CategoryRepository
        if inMemory {
            transactionRepository = InMemoryTransactionRepository()
            categoryRepository = InMemoryCategoryRepository()
        } else {
            let metadata = MetadataStore()
            categoryRepository = CategoryRepositoryImpl(
                api: apiClient,
                metadata: metadata
            )
            transactionRepository = TransactionRepositoryImpl(
                api: apiClient,
                accounts: accountRepository,
                metadata: metadata
            )
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
                categories: categoryRepository,
                transactions: transactionRepository
            ),
            accounts: AccountUseCases(
                accounts: accountRepository,
                transactions: transactionRepository
            ),
            includeCategories: inMemory,
            includeAccounts: inMemory
        )
    }

    func bootstrap() async {
        await defaultDataSeeder.seedIfNeeded()
    }
}
