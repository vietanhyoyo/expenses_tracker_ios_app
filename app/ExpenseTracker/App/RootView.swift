import SwiftUI
import UIKit

struct RootView: View {
    let container: AppContainer
    @State private var session: SessionViewModel
    @State private var isReady = false
    @State private var selectedTab = 0

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
            if isAuthenticated {
                selectedTab = 0
            }
            updateStatusBarStyle()
        }
        .onChange(of: selectedTab) { _, _ in
            updateStatusBarStyle()
        }
        .preferredColorScheme(session.isAuthenticated ? .light : .dark)
        .environment(\.locale, AppFormatters.locale)
        .environment(\.calendar, AppFormatters.calendar)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                factory: container,
                userEmail: session.user?.email,
                onShowTransactions: { selectedTab = 1 }
            )
                .tabItem { Label("Tổng quan", systemImage: "square.grid.2x2.fill") }
                .tag(0)
            TransactionListView(factory: container)
                .tabItem { Label("Giao dịch", systemImage: "arrow.left.arrow.right") }
                .tag(1)
            StatisticsView(viewModel: container.makeStatisticsViewModel())
                .tabItem { Label("Thống kê", systemImage: "chart.bar.xaxis") }
                .tag(2)
            SettingsView(factory: container, session: session)
                .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
                .tag(3)
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
            (selectedTab == 0 ? AppTheme.elevatedSurface : AppTheme.background)
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case 0:
            DashboardView(
                factory: container,
                userEmail: session.user?.email,
                onShowTransactions: { selectedTab = 1 }
            )
        case 1:
            TransactionListView(factory: container)
        case 2:
            StatisticsView(viewModel: container.makeStatisticsViewModel())
        default:
            SettingsView(factory: container, session: session)
        }
    }

    private var iPadBottomNavigation: some View {
        HStack(spacing: AppSpacing.xxxSmall) {
            ForEach(Array(zip(tabTitles.indices, tabTitles)), id: \.0) { index, title in
                Button {
                    selectedTab = index
                } label: {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .foregroundStyle(index == selectedTab ? AppTheme.primary : .secondary)
                        .background(
                            index == selectedTab
                                ? AppTheme.primary.opacity(0.1)
                                : .clear,
                            in: Capsule(style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(index == selectedTab ? .isSelected : [])
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

    private let tabTitles = ["Tổng quan", "Giao dịch", "Thống kê", "Cài đặt"]

    @MainActor
    private func updateStatusBarStyle() {
        let isIPhoneDashboard =
            UIDevice.current.userInterfaceIdiom == .phone && selectedTab == 0

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
