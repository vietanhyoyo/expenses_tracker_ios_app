import SwiftUI

struct TransactionListView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: TransactionListViewModel
    @State private var editingTransaction: ExpenseTransaction?
    @State private var showingAdd = false
    @State private var showingFilters = false
    @State private var successMessage: String?

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeTransactionListViewModel())
    }

    var body: some View {
        let sections = viewModel.daySections

        NavigationStack {
            Group {
                if viewModel.isInitialLoading {
                    ProgressView("Đang tải giao dịch…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sections.isEmpty {
                    emptyState
                } else {
                    transactionList(sections)
                }
            }
            .appScreenBackground()
            .navigationTitle("Giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, prompt: "Ghi chú hoặc danh mục")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingFilters = true } label: {
                        Image(systemName: filterIcon)
                    }
                    .accessibilityLabel("Bộ lọc")
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Thêm giao dịch")
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showingAdd, onDismiss: reload) {
                TransactionFormView(
                    viewModel: factory.makeTransactionFormViewModel(transaction: nil),
                    onSuccess: { successMessage = $0 }
                )
            }
            .sheet(item: $editingTransaction, onDismiss: reload) { item in
                TransactionFormView(
                    viewModel: factory.makeTransactionFormViewModel(transaction: item),
                    onSuccess: { successMessage = $0 }
                )
            }
            .sheet(isPresented: $showingFilters) {
                TransactionFilterView(viewModel: viewModel)
            }
            .errorAlert(message: $viewModel.errorMessage)
            .successToast(message: $successMessage)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.hasSearchOrFilters {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Không tìm thấy",
                message: "Thử thay đổi từ khoá hoặc bộ lọc."
            )
        } else {
            EmptyStateView(
                icon: "tray",
                title: "Chưa có giao dịch",
                message: "Nhấn nút + để ghi lại khoản thu chi đầu tiên."
            )
        }
    }

    private func transactionList(_ sections: [TransactionDayGroup]) -> some View {
        List {
            ForEach(sections) { section in
                TransactionDaySection(
                    day: section.day,
                    transactions: section.transactions,
                    categories: viewModel.categories,
                    accounts: viewModel.accounts,
                    onEdit: { editingTransaction = $0 },
                    onDelete: { transaction in
                        Task { await viewModel.delete(transaction) }
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var filterIcon: String {
        viewModel.hasFilters
            ? "line.3.horizontal.decrease.circle.fill"
            : "line.3.horizontal.decrease.circle"
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}
