import SwiftUI

struct DashboardView: View {
    private let factory: any ViewModelFactory
    private let userEmail: String?
    private let onShowTransactions: () -> Void
    @State private var viewModel: DashboardViewModel
    @State private var isShowingTransactionForm = false
    @State private var successMessage: String?

    init(
        factory: any ViewModelFactory,
        userEmail: String? = nil,
        onShowTransactions: @escaping () -> Void = {}
    ) {
        self.factory = factory
        self.userEmail = userEmail
        self.onShowTransactions = onShowTransactions
        _viewModel = State(initialValue: factory.makeDashboardViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.elevatedSurface.ignoresSafeArea()

                Image("HomeBackground")
                    .resizable()
                    .aspectRatio(497.0 / 794.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        dashboardHeader
                        VStack(spacing: AppSpacing.xLarge) {
                            StatisticsPeriodSelector(
                                period: viewModel.selectedPeriod,
                                date: viewModel.selectedDate,
                                previous: { Task { await viewModel.movePeriod(-1) } },
                                next: { Task { await viewModel.movePeriod(1) } },
                                selectPeriod: { period, date in
                                    Task { await viewModel.selectPeriod(period, date: date) }
                                }
                            )
                            DashboardPillDivider()
                            if let errorMessage = viewModel.errorMessage {
                                ErrorBanner(message: errorMessage)
                            }
                            DashboardSpendingCard(items: viewModel.categorySpending)
                            if !viewModel.budgetProgress.isEmpty {
                                DashboardBudgetCard(items: viewModel.budgetProgress)
                            }
                            DashboardPillDivider()
                            DashboardRecentCard(
                                transactions: viewModel.recentTransactions,
                                categories: viewModel.categories,
                                onShowAll: onShowTransactions
                            )
                        }
                        .padding(.horizontal, AppSpacing.xLarge)
                        .padding(.top, AppSpacing.xLarge)
                        .padding(.bottom, 96)
                        .frame(maxWidth: .infinity)
                        .background(
                            AppTheme.elevatedSurface,
                            in: UnevenRoundedRectangle(
                                topLeadingRadius: 38,
                                topTrailingRadius: 38,
                                style: .continuous
                            )
                        )
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                    viewModel: factory.makeTransactionFormViewModel(transaction: nil),
                    onSuccess: { successMessage = $0 }
                )
            }
            .successToast(message: $successMessage)
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(spacing: AppSpacing.small) {
                Text(userInitials)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle().stroke(.white.opacity(0.9), lineWidth: 1.2)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Xin chào!")
                        .font(AppTypography.captionEmphasis)
                        .foregroundStyle(.white)
                    Text(userEmail ?? "Tài khoản của bạn")
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            Rectangle()
                .stroke(
                    .white.opacity(0.65),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 3])
                )
                .frame(height: 1)

            DashboardBalanceCard(
                balance: viewModel.balance,
                summary: viewModel.summary,
                period: viewModel.selectedPeriod
            )
        }
        .padding(.horizontal, AppSpacing.xLarge)
        .padding(.top, AppSpacing.xSmall)
        .padding(.bottom, AppSpacing.xLarge)
    }

    private var userInitials: String {
        let localPart = userEmail?.split(separator: "@").first.map(String.init) ?? "TK"
        return String(localPart.prefix(2)).uppercased()
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
