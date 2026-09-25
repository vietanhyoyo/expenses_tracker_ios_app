import SwiftUI

struct DashboardView: View {
    private enum LayoutMode {
        case iPhonePortrait
        case iPadPortrait
        case iPadLandscape
    }

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
        if UIDevice.current.userInterfaceIdiom == .pad {
            GeometryReader { proxy in
                dashboardScreen(mode: layoutMode(for: proxy.size), size: proxy.size)
            }
        } else {
            dashboardScreen(mode: .iPhonePortrait, size: .zero)
        }
    }

    private func dashboardScreen(mode: LayoutMode, size: CGSize) -> some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppTheme.elevatedSurface.ignoresSafeArea()

                if mode == .iPhonePortrait {
                    Image("HomeBackground")
                        .resizable()
                        .aspectRatio(497.0 / 794.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                }

                VStack(spacing: 0) {
                    if mode != .iPhonePortrait {
                        HStack {
                            Spacer()
                            addTransactionButton(for: mode)
                        }
                        .padding(.horizontal, AppSpacing.xLarge)
                        .frame(height: 76)
                    }

                    if mode == .iPadLandscape {
                        dashboardContent(for: mode, size: size)
                            .frame(maxHeight: .infinity, alignment: .top)
                    } else {
                        ScrollView {
                            dashboardContent(for: mode, size: size)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if mode == .iPhonePortrait {
                    ToolbarItem(placement: .topBarTrailing) {
                        addTransactionButton(for: mode)
                    }
                }
            }
            .toolbar(mode == .iPhonePortrait ? .visible : .hidden, for: .navigationBar)
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
                .transactionFormSheetPresentation()
            }
            .successToast(message: $successMessage)
        }
    }

    @ViewBuilder
    private func dashboardContent(for mode: LayoutMode, size: CGSize) -> some View {
        switch mode {
        case .iPhonePortrait:
            LazyVStack(spacing: 0) {
                dashboardHeader
                VStack(spacing: AppSpacing.xLarge) {
                    dashboardSections(for: mode)
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

        case .iPadPortrait:
            VStack(spacing: AppSpacing.xLarge) {
                iPadHero(height: 318)
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    dashboardSections(for: mode)
                }
                    .padding(AppSpacing.xLarge)
                    .background(
                        AppTheme.elevatedSurface,
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .shadow(color: AppTheme.navy.opacity(0.06), radius: 14, y: 6)
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.vertical, AppSpacing.large)
            .frame(maxWidth: 840)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 72)
            .dynamicTypeSize(.xxxLarge)

        case .iPadLandscape:
            let heroWidth = min(max(size.width * 0.34, 310), 420)

            HStack(alignment: .top, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    iPadHero(height: 390)
                    dashboardPeriodSelector(for: mode)
                }
                .frame(width: heroWidth, alignment: .top)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        dashboardSections(for: mode)
                    }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.bottom, 72)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: 1280)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .dynamicTypeSize(.xxxLarge)
        }
    }

    private func iPadHero(height: CGFloat) -> some View {
        ZStack {
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            dashboardHeader
                .padding(.horizontal, AppSpacing.small)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.primary.opacity(0.18), radius: 18, y: 8)
    }

    @ViewBuilder
    private func dashboardSections(for mode: LayoutMode) -> some View {
        if mode != .iPadLandscape {
            dashboardPeriodSelector(for: mode)
            DashboardPillDivider()
        }

        if let errorMessage = viewModel.errorMessage {
            ErrorBanner(message: errorMessage)
        }

        dashboardCard(
            DashboardSpendingCard(items: viewModel.categorySpending),
            for: mode
        )

        if !viewModel.budgetProgress.isEmpty {
            dashboardCard(
                DashboardBudgetCard(items: viewModel.budgetProgress),
                for: mode
            )
        }

        DashboardPillDivider()

        dashboardCard(
            DashboardRecentCard(
                transactions: viewModel.recentTransactions,
                categories: viewModel.categories,
                onShowAll: onShowTransactions
            ),
            for: mode
        )
    }

    @ViewBuilder
    private func dashboardPeriodSelector(for mode: LayoutMode) -> some View {
        dashboardCard(
            StatisticsPeriodSelector(
                period: viewModel.selectedPeriod,
                date: viewModel.selectedDate,
                usesLargeText: mode != .iPhonePortrait,
                previous: { Task { await viewModel.movePeriod(-1) } },
                next: { Task { await viewModel.movePeriod(1) } },
                selectPeriod: { period, date in
                    Task { await viewModel.selectPeriod(period, date: date) }
                }
            ),
            for: mode
        )
    }

    @ViewBuilder
    private func dashboardCard<Content: View>(
        _ content: Content,
        for mode: LayoutMode
    ) -> some View {
        if mode == .iPhonePortrait {
            content
        } else {
            content
                .appCard(
                    padding: mode == .iPadLandscape ? AppSpacing.medium : AppSpacing.large,
                    cornerRadius: AppRadius.large,
                    shadow: false
                )
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(spacing: AppSpacing.small) {
                Text(userInitials)
                    .font(
                        isPad
                            ? .system(size: 18, weight: .medium, design: .rounded)
                            : .system(.body, design: .rounded).weight(.medium)
                    )
                    .foregroundStyle(.white)
                    .frame(width: isPad ? 48 : 40, height: isPad ? 48 : 40)
                    .background(
                        usesLegacyPhoneStyle
                            ? Color.white.opacity(0.14)
                            : Color.clear,
                        in: Circle()
                    )
                    .overlay {
                        Circle().stroke(.white.opacity(0.9), lineWidth: 1.2)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Xin chào!")
                        .font(
                            isPad
                                ? .system(size: 18, weight: .semibold, design: .rounded)
                                : AppTypography.captionEmphasis
                        )
                        .foregroundStyle(.white)
                    Text(userEmail ?? "Tài khoản của bạn")
                        .font(
                            isPad
                                ? .system(size: 20, weight: .semibold, design: .rounded)
                                : AppTypography.bodyEmphasis
                        )
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var userInitials: String {
        let localPart = userEmail?.split(separator: "@").first.map(String.init) ?? "TK"
        return String(localPart.prefix(2)).uppercased()
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var usesLegacyPhoneStyle: Bool {
        guard !isPad else { return false }
        if #available(iOS 26.0, *) {
            return false
        }
        return true
    }

    @ViewBuilder
    private func addTransactionButton(for mode: LayoutMode) -> some View {
        Button { isShowingTransactionForm = true } label: {
            if mode == .iPhonePortrait {
                if usesLegacyPhoneStyle {
                    // iOS 17 needs a solid surface so the action remains
                    // visible over the transparent navigation bar.
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.elevatedSurface, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(AppTheme.primary.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: AppTheme.navy.opacity(0.1), radius: 8, y: 3)
                        .contentShape(Circle())
                } else {
                    // Preserve the original iOS 26 appearance.
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.primary)
                }
            } else {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 58, height: 58)
                    .background(AppTheme.elevatedSurface, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(AppTheme.primary.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(color: AppTheme.navy.opacity(0.1), radius: 10, y: 4)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Thêm giao dịch")
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

#Preview {
    DashboardView(factory: try! AppContainer(inMemory: true))
}
