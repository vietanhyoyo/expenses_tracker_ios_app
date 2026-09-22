import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                TabView {
                    DashboardView(factory: container)
                        .tabItem { Label("Tổng quan", systemImage: "square.grid.2x2.fill") }
                    TransactionListView(factory: container)
                        .tabItem { Label("Giao dịch", systemImage: "arrow.left.arrow.right") }
                    StatisticsView(viewModel: container.makeStatisticsViewModel())
                        .tabItem { Label("Thống kê", systemImage: "chart.bar.xaxis") }
                    SettingsView(factory: container)
                        .tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }
                }
                .tint(AppTheme.teal)
                .toolbarBackground(AppTheme.elevatedSurface, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            } else {
                VStack(spacing: AppSpacing.large) {
                    AppIconBadge(icon: "wallet.bifold.fill", color: AppTheme.teal, size: 72)
                    VStack(spacing: AppSpacing.xSmall) {
                        Text("Sổ Thu Chi")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("Đang chuẩn bị dữ liệu của bạn…")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView()
                        .tint(AppTheme.teal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appScreenBackground()
            }
        }
        .task {
            await container.bootstrap()
            isReady = true
        }
    }
}
