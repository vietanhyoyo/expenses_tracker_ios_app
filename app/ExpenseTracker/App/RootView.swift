import SwiftUI
import UIKit

struct RootView: View {
    let container: AppContainer
    @State private var session: SessionViewModel
    @State private var router = AppRouter()
    @State private var isReady = false

    init(container: AppContainer) {
        self.container = container
        _session = State(initialValue: container.makeSessionViewModel())
    }

    var body: some View {
        Group {
            if session.isRestoring {
                loadingView(message: "Đang kiểm tra phiên đăng nhập…")
            } else if !session.isAuthenticated {
                AuthView(viewModel: session)
            } else if isReady {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadTabView
                } else {
                    mainTabView
                }
            } else {
                loadingView(message: "Đang chuẩn bị dữ liệu của bạn…")
                    .task {
                        await container.bootstrap()
                        isReady = true
                    }
            }
        }
        .task {
            await session.restore()
        }
        .onAppear(perform: updateStatusBarStyle)
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            router.reset()
            if !isAuthenticated { isReady = false }
            updateStatusBarStyle()
        }
        .onChange(of: router.selectedTab) { _, _ in
            updateStatusBarStyle()
        }
        .preferredColorScheme(session.isAuthenticated ? .light : .dark)
        .environment(\.locale, AppFormatters.locale)
        .environment(\.calendar, AppFormatters.calendar)
    }

    private var mainTabView: some View {
        TabView(selection: $router.selectedTab) {
            DashboardView(
                factory: container,
                userEmail: session.user?.email,
                onShowTransactions: router.showTransactions
            )
                .tabItem { Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.symbol) }
                .tag(AppTab.dashboard)
            TransactionListView(factory: container)
                .tabItem { Label(AppTab.transactions.title, systemImage: AppTab.transactions.symbol) }
                .tag(AppTab.transactions)
            StatisticsView(viewModel: container.makeStatisticsViewModel())
                .tabItem { Label(AppTab.statistics.title, systemImage: AppTab.statistics.symbol) }
                .tag(AppTab.statistics)
            SettingsView(factory: container, session: session, router: router)
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbol) }
                .tag(AppTab.settings)
        }
        .tint(AppTheme.teal)
        .toolbarBackground(AppTheme.elevatedSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    private var iPadTabView: some View {
        ZStack(alignment: .bottom) {
            selectedTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            iPadBottomNavigation
        }
        .background(
            (router.selectedTab == .dashboard ? AppTheme.elevatedSurface : AppTheme.background)
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch router.selectedTab {
        case .dashboard:
            DashboardView(
                factory: container,
                userEmail: session.user?.email,
                onShowTransactions: router.showTransactions
            )
        case .transactions:
            TransactionListView(factory: container)
        case .statistics:
            StatisticsView(viewModel: container.makeStatisticsViewModel())
        case .settings:
            SettingsView(factory: container, session: session, router: router)
        }
    }

    private var iPadBottomNavigation: some View {
        HStack(spacing: AppSpacing.xxxSmall) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    router.selectTab(tab)
                } label: {
                    Text(tab.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .foregroundStyle(tab == router.selectedTab ? AppTheme.primary : .secondary)
                        .background(
                            tab == router.selectedTab
                                ? AppTheme.primary.opacity(0.1)
                                : .clear,
                            in: Capsule(style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(tab == router.selectedTab ? .isSelected : [])
            }
        }
        .padding(AppSpacing.xxSmall)
        .background(
            AppTheme.elevatedSurface,
            in: Capsule(style: .continuous)
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
        .shadow(color: AppTheme.navy.opacity(0.1), radius: 12, y: -3)
        .padding(.top, AppSpacing.xxxSmall)
        .padding(.bottom, AppSpacing.medium)
    }

    @MainActor
    private func updateStatusBarStyle() {
        let isIPhoneDashboard =
            UIDevice.current.userInterfaceIdiom == .phone && router.selectedTab == .dashboard

        UIApplication.shared.statusBarStyle =
            !session.isAuthenticated || isIPhoneDashboard ? .lightContent : .darkContent
    }

    private func loadingView(message: String) -> some View {
        VStack(spacing: AppSpacing.large) {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: AppTheme.primary.opacity(0.22), radius: 16, y: 8)
            VStack(spacing: AppSpacing.xSmall) {
                Text("Sổ Thu Chi")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView().tint(AppTheme.teal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
    }
}
