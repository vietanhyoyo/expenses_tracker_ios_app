import Foundation

@MainActor
protocol DashboardRepository {
    func getSummary(month: Date) async throws -> DashboardSummary
}
