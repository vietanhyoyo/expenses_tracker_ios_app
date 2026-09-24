import SwiftUI

struct AccountsView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: AccountsViewModel

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeAccountsViewModel())
    }

    var body: some View {
        List {
            if viewModel.accounts.isEmpty {
                EmptyStateView(icon: "wallet.bifold", title: "Chưa có tài khoản", message: "Chưa có dữ liệu ví hoặc tài khoản ngân hàng để hiển thị.")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(viewModel.accounts) { account in
                accountRow(account)
            }
        }
        .appFormStyle()
        .navigationTitle("Tài khoản")
        .task { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .appLoadingOverlay(viewModel.isLoading, message: "Đang tải tài khoản…")
    }

    private func accountRow(_ account: Account) -> some View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), số dư hiện tại")
        .accessibilityValue(AppFormatters.money(viewModel.balance(for: account)))
    }
}
