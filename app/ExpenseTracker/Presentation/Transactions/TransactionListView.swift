import SwiftUI

struct TransactionListView: View {
    private enum LayoutMode: Equatable {
        case iPhonePortrait
        case iPadPortrait
        case iPadLandscape
    }

    private let factory: any ViewModelFactory
    @State private var viewModel: TransactionListViewModel

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeTransactionListViewModel())
    }

    var body: some View {
        GeometryReader { proxy in
            let mode = layoutMode(for: proxy.size)
            let sections = viewModel.daySections

            NavigationStack {
                VStack(spacing: 0) {
                    if mode != .iPhonePortrait {
                        iPadNavigationHeader(mode: mode)
                    }

                    Group {
                        if sections.isEmpty {
                            emptyState
                        } else {
                            transactionList(sections)
                        }
                    }
                    .frame(maxWidth: mode == .iPhonePortrait ? .infinity : 1100)
                    .frame(maxWidth: .infinity)
                }
                .appScreenBackground()
                .navigationTitle(mode == .iPhonePortrait ? "Giao dịch" : "")
                .navigationBarTitleDisplayMode(.inline)
                .modifier(
                    TransactionSearchModifier(
                        text: $viewModel.query,
                        isEnabled: mode == .iPhonePortrait
                    )
                )
                .toolbar {
                    if mode == .iPhonePortrait {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button { viewModel.showFilters() } label: {
                                Image(systemName: viewModel.filterIcon)
                            }
                            .accessibilityLabel("Bộ lọc")
                            Button { viewModel.showAddForm() } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .accessibilityLabel("Thêm giao dịch")
                        }
                    }
                }
                .toolbar(mode == .iPhonePortrait ? .visible : .hidden, for: .navigationBar)
                .task { await viewModel.load() }
                .refreshable { await viewModel.load() }
                .sheet(isPresented: $viewModel.isShowingAddForm, onDismiss: reload) {
                    TransactionFormView(
                        viewModel: factory.makeTransactionFormViewModel(transaction: nil),
                        onSuccess: viewModel.handleFormSuccess
                    )
                    .transactionFormSheetPresentation()
                }
                .sheet(item: $viewModel.editingTransaction, onDismiss: reload) { item in
                    TransactionFormView(
                        viewModel: factory.makeTransactionFormViewModel(transaction: item),
                        onSuccess: viewModel.handleFormSuccess
                    )
                    .transactionFormSheetPresentation()
                }
                .sheet(isPresented: $viewModel.isShowingFilters) {
                    TransactionFilterView(viewModel: viewModel)
                }
                .alert(
                    "Xoá giao dịch?",
                    isPresented: $viewModel.isShowingDeleteConfirmation
                ) {
                    Button("Huỷ", role: .cancel) { viewModel.cancelDeletion() }
                    Button("Xoá", role: .destructive) {
                        Task { await viewModel.confirmDeletion() }
                    }
                } message: {
                    Text("Giao dịch này sẽ bị xoá vĩnh viễn và không thể hoàn tác.")
                }
                .errorAlert(message: $viewModel.errorMessage)
                .successToast(message: $viewModel.successMessage)
            }
            .appIPadTypography(isEnabled: mode != .iPhonePortrait)
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
                    onEdit: viewModel.edit,
                    onDelete: viewModel.requestDeletion
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private func iPadNavigationHeader(mode: LayoutMode) -> some View {
        VStack(spacing: AppSpacing.xSmall) {
            ZStack {
                Text("Giao dịch")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                HStack {
                    Spacer()
                    iPadToolbarControls
                }
            }

            iPadSearchField
                .padding(
                    .horizontal,
                    mode == .iPadLandscape ? AppSpacing.xLarge : 0
                )
                .frame(maxWidth: mode == .iPadLandscape ? 1100 : .infinity)
        }
        .padding(.horizontal, AppSpacing.xLarge)
        .padding(.vertical, AppSpacing.xSmall)
        .background(AppTheme.background)
    }

    private var iPadToolbarControls: some View {
        HStack(spacing: AppSpacing.xxSmall) {
            Button { viewModel.showFilters() } label: {
                Image(systemName: viewModel.filterIcon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.primary.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bộ lọc")

            Button { viewModel.showAddForm() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.primary, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thêm giao dịch")
        }
        .padding(6)
        .background(AppTheme.elevatedSurface, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppTheme.primary.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: AppTheme.navy.opacity(0.08), radius: 10, y: 4)
    }

    private var iPadSearchField: some View {
        HStack(spacing: AppSpacing.xxSmall) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.primary)
            TextField("Ghi chú hoặc danh mục", text: $viewModel.query)
                .font(.system(size: 18, weight: .regular))
                .textFieldStyle(.plain)
            if !viewModel.query.isEmpty {
                Button { viewModel.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Xoá nội dung tìm kiếm")
            }
        }
        .padding(.horizontal, AppSpacing.small)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(Color(uiColor: .systemFill), in: Capsule(style: .continuous))
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    private func layoutMode(for size: CGSize) -> LayoutMode {
        if size.width >= 900 && size.width > size.height {
            return .iPadLandscape
        }
        if size.width >= 600 {
            return .iPadPortrait
        }
        return .iPhonePortrait
    }
}

private struct TransactionSearchModifier: ViewModifier {
    @Binding var text: String
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: "Ghi chú hoặc danh mục")
        } else {
            content
        }
    }
}
