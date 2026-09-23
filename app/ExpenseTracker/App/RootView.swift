import SwiftUI

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
        .environment(\.locale, AppFormatters.locale)
        .environment(\.calendar, AppFormatters.calendar)
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
