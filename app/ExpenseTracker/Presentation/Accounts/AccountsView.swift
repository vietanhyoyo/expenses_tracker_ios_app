import SwiftUI

struct AccountsView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: AccountsViewModel
    @State private var editingAccount: Account?
    @State private var isShowingForm = false

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeAccountsViewModel())
    }

    var body: some View {
        List {
            if viewModel.accounts.isEmpty {
                EmptyStateView(icon: "wallet.bifold", title: "Chưa có tài khoản", message: "Tạo ví hoặc tài khoản ngân hàng để bắt đầu.")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(viewModel.accounts) { account in
                accountRow(account)
            }
        }
        .appFormStyle()
        .navigationTitle("Tài khoản")
        .toolbar {
            Button { isShowingForm = true } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Thêm tài khoản")
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $isShowingForm, onDismiss: reload) {
            AccountFormView(viewModel: factory.makeAccountFormViewModel(account: nil))
        }
        .sheet(item: $editingAccount, onDismiss: reload) { account in
            AccountFormView(viewModel: factory.makeAccountFormViewModel(account: account))
        }
        .errorAlert(message: $viewModel.errorMessage)
    }

    private func accountRow(_ account: Account) -> some View {
        Button { editingAccount = account } label: {
            HStack(spacing: AppSpacing.small) {
                AppIconBadge(icon: "wallet.bifold.fill", color: AppTheme.teal)
                VStack(alignment: .leading, spacing: AppSpacing.xxxSmall) {
                    Text(account.name)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(.primary)
                    Text("Số dư hiện tại")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(AppFormatters.money(viewModel.balance(for: account)))
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, AppSpacing.xxxSmall)
        }
        .swipeActions {
            Button("Xoá", role: .destructive) {
                Task { await viewModel.delete(account) }
            }
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}
