import Foundation

@MainActor
final class DashboardRepositoryImpl: DashboardRepository {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getSummary(period: String, date: Date) async throws -> DashboardSummary {
        do {
            let value: DashboardSummaryDTO = try await api.get(
                "/dashboard/summary",
                queryItems: [
                    URLQueryItem(name: "period", value: period),
                    URLQueryItem(
                        name: "date",
                        value: DateParser.calendarDate(from: date)
                    )
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
            throw ErrorMapper.map(error)
        }
    }

    private func decimal(_ value: String) -> Decimal? {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }
}
