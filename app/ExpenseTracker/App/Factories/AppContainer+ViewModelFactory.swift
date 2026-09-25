import Foundation

extension AppContainer: ViewModelFactory {
    func makeSessionViewModel() -> SessionViewModel {
        let viewModel = SessionViewModel(authUseCases: authUseCases)
        apiClient.onSessionInvalidated = { [weak viewModel] in
            viewModel?.sessionDidExpire()
        }
        return viewModel
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            dashboardUseCases: dashboardUseCases,
            statisticsUseCases: statisticsUseCases,
            categoryUseCases: categoryUseCases,
            budgetUseCases: budgetUseCases
        )
    }

    func makeTransactionListViewModel() -> TransactionListViewModel {
        TransactionListViewModel(
            transactionUseCases: transactionUseCases,
            categoryUseCases: categoryUseCases,
            accountUseCases: accountUseCases
        )
    }

    func makeTransactionFormViewModel(
        transaction: ExpenseTransaction?
    ) -> TransactionFormViewModel {
        TransactionFormViewModel(
            existing: transaction,
            transactionUseCases: transactionUseCases,
            categoryUseCases: categoryUseCases,
            accountUseCases: accountUseCases
        )
    }

    func makeStatisticsViewModel() -> StatisticsViewModel {
        StatisticsViewModel(statisticsUseCases: statisticsUseCases)
    }

    func makeAccountsViewModel() -> AccountsViewModel {
        AccountsViewModel(accountUseCases: accountUseCases)
    }

    func makeAccountFormViewModel(account: Account?) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountUseCases: accountUseCases)
    }

    func makeBudgetsViewModel() -> BudgetsViewModel {
        BudgetsViewModel(budgetUseCases: budgetUseCases)
    }

    func makeBudgetFormViewModel(budget: Budget?, month: Date) -> BudgetFormViewModel {
        BudgetFormViewModel(
            budget: budget,
            month: month,
            budgetUseCases: budgetUseCases,
            categoryUseCases: categoryUseCases
        )
    }

    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel(categoryUseCases: categoryUseCases)
    }

    func makeCategoryFormViewModel(category: ExpenseCategory?) -> CategoryFormViewModel {
        CategoryFormViewModel(category: category, categoryUseCases: categoryUseCases)
    }
}
