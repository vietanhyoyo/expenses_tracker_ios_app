import Foundation

extension AppContainer: ViewModelFactory {
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            statistics: statisticsUseCases,
            accounts: accountUseCases,
            categories: categoryUseCases,
            budgets: budgetUseCases
        )
    }

    func makeTransactionListViewModel() -> TransactionListViewModel {
        TransactionListViewModel(
            transactions: transactionUseCases,
            categories: categoryUseCases,
            accounts: accountUseCases
        )
    }

    func makeTransactionFormViewModel(
        transaction: ExpenseTransaction?
    ) -> TransactionFormViewModel {
        TransactionFormViewModel(
            existing: transaction,
            transactions: transactionUseCases,
            categories: categoryUseCases,
            accounts: accountUseCases
        )
    }

    func makeStatisticsViewModel() -> StatisticsViewModel {
        StatisticsViewModel(statistics: statisticsUseCases)
    }

    func makeAccountsViewModel() -> AccountsViewModel {
        AccountsViewModel(useCases: accountUseCases)
    }

    func makeAccountFormViewModel(account: Account?) -> AccountFormViewModel {
        AccountFormViewModel(account: account, useCases: accountUseCases)
    }

    func makeBudgetsViewModel() -> BudgetsViewModel {
        BudgetsViewModel(budgets: budgetUseCases)
    }

    func makeBudgetFormViewModel(budget: Budget?, month: Date) -> BudgetFormViewModel {
        BudgetFormViewModel(
            budget: budget,
            month: month,
            budgets: budgetUseCases,
            categories: categoryUseCases
        )
    }

    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel(useCases: categoryUseCases)
    }

    func makeCategoryFormViewModel(category: ExpenseCategory?) -> CategoryFormViewModel {
        CategoryFormViewModel(category: category, useCases: categoryUseCases)
    }
}
