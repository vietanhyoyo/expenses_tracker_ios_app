import Observation

enum AppTab: CaseIterable, Hashable {
    case dashboard
    case transactions
    case statistics
    case settings

    var title: String {
        switch self {
        case .dashboard: "Tổng quan"
        case .transactions: "Giao dịch"
        case .statistics: "Thống kê"
        case .settings: "Cài đặt"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2.fill"
        case .transactions: "arrow.left.arrow.right"
        case .statistics: "chart.bar.xaxis"
        case .settings: "gearshape.fill"
        }
    }
}

enum SettingsRoute: Hashable {
    case accounts
    case categories
    case privacyPolicy
    case privacyRights
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .dashboard
    var settingsPath: [SettingsRoute] = []

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func showTransactions() {
        selectTab(.transactions)
    }

    func reset() {
        settingsPath.removeAll()
        selectedTab = .dashboard
    }
}
