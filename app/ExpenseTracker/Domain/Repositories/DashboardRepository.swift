import Foundation

@MainActor
protocol DashboardRepository {
    func getSummary(period: String, date: Date) async throws -> DashboardSummary
}
