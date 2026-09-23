import Foundation

@MainActor
struct DashboardUseCases {
    let repository: any DashboardRepository

    func summary(for month: Date) async throws -> DashboardSummary {
        try await repository.getSummary(month: month)
    }
}
