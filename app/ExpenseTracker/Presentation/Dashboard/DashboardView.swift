import SwiftUI

struct DashboardView: View {
    private let factory: any ViewModelFactory
    private let onShowTransactions: () -> Void
    @State private var viewModel: DashboardViewModel
    @State private var isShowingTransactionForm = false

    init(
        factory: any ViewModelFactory,
        onShowTransactions: @escaping () -> Void = {}
    ) {
        self.factory = factory
        self.onShowTransactions = onShowTransactions
        _viewModel = State(initialValue: factory.makeDashboardViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    MonthSelector(
                        month: viewModel.selectedMonth,
                        previous: { Task { await viewModel.moveMonth(-1) } },
                        next: { Task { await viewModel.moveMonth(1) } }
                    )
                    DashboardBalanceCard(
                        balance: viewModel.balance,
                        summary: viewModel.summary
                    )
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    DashboardSpendingCard(items: viewModel.categorySpending)
                    if !viewModel.budgetProgress.isEmpty {
                        DashboardBudgetCard(items: viewModel.budgetProgress)
                    }
                    DashboardRecentCard(
                        transactions: viewModel.recentTransactions,
                        categories: viewModel.categories,
                        onShowAll: onShowTransactions
                    )
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.xSmall)
                .padding(.bottom, AppSpacing.xxLarge)
            }
            .appScreenBackground()
            .navigationTitle("Xin chào 👋")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addTransactionButton
                }
            }
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .sheet(
                isPresented: $isShowingTransactionForm,
                onDismiss: { Task { await viewModel.load() } }
            ) {
                TransactionFormView(
                    viewModel: factory.makeTransactionFormViewModel(transaction: nil)
                )
            }
        }
    }

    private var addTransactionButton: some View {
        Button { isShowingTransactionForm = true } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
        }
        .accessibilityLabel("Thêm giao dịch")
    }
}

#Preview {
    // Previews compose the real dependency graph with an in-memory store.
    DashboardView(factory: try! AppContainer(inMemory: true))
}
