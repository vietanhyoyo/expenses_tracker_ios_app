import Foundation

/// Creates ViewModels for views that present other screens.
/// Declared in Presentation and implemented by the composition root (`AppContainer`),
/// so views never depend on the App layer.
@MainActor
protocol ViewModelFactory {
    func makeDashboardViewModel() -> DashboardViewModel
    func makeTransactionListViewModel() -> TransactionListViewModel
    func makeTransactionFormViewModel(transaction: ExpenseTransaction?) -> TransactionFormViewModel
    func makeStatisticsViewModel() -> StatisticsViewModel
    func makeAccountsViewModel() -> AccountsViewModel
    func makeAccountFormViewModel(account: Account?) -> AccountFormViewModel
    func makeBudgetsViewModel() -> BudgetsViewModel
    func makeBudgetFormViewModel(budget: Budget?, month: Date) -> BudgetFormViewModel
    func makeCategoriesViewModel() -> CategoriesViewModel
    func makeCategoryFormViewModel(category: ExpenseCategory?) -> CategoryFormViewModel
}
