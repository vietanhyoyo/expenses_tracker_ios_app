import Foundation

@MainActor
final class RemoteDashboardRepository: DashboardRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getSummary(month: Date) async throws -> DashboardSummary {
        do {
            let value: DashboardSummaryDTO = try await api.get(
                "/dashboard/summary",
                queryItems: [
                    URLQueryItem(name: "month", value: monthValue(from: month))
                ]
            )
            guard let totalBalance = decimal(value.totalBalance),
                  let monthlyIncome = decimal(value.monthlyIncome),
                  let monthlyExpense = decimal(value.monthlyExpense),
                  let monthlyBalance = decimal(value.monthlyBalance) else {
                throw DomainError.remoteError("Dữ liệu tổng quan từ máy chủ không hợp lệ.")
            }
            return DashboardSummary(
                month: value.month,
                totalBalance: totalBalance,
                monthlyIncome: monthlyIncome,
                monthlyExpense: monthlyExpense,
                monthlyBalance: monthlyBalance
            )
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    private func decimal(_ value: String) -> Decimal? {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func monthValue(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
