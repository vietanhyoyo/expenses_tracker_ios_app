import Foundation

@MainActor
struct DashboardUseCases {
    let repository: any DashboardRepository

    func summary(for period: String, date: Date) async throws -> DashboardSummary {
        try await repository.getSummary(period: period, date: date)
    }
}
