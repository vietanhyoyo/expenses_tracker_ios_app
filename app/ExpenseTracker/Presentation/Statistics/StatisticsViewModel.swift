import Foundation
import Observation

enum StatisticsPeriod: String, CaseIterable, Sendable {
    case week
    case month
    case year

    var title: String {
        switch self {
        case .week: "Tuần"
        case .month: "Tháng"
        case .year: "Năm"
        }
    }

    func interval(for date: Date, calendar: Calendar) -> DateInterval? {
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2
        weekCalendar.minimumDaysInFirstWeek = 4
        switch self {
        case .week:
            return weekCalendar.dateInterval(of: .weekOfYear, for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)
        case .year:
            return calendar.dateInterval(of: .year, for: date)
        }
    }

    func displayValue(for date: Date, calendar: Calendar) -> String {
        guard let interval = interval(for: date, calendar: calendar) else {
            return AppFormatters.dateString(date)
        }
        switch self {
        case .week:
            let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(AppFormatters.dateString(interval.start)) – \(AppFormatters.dateString(end))"
        case .month:
            return AppFormatters.monthYear.string(from: interval.start)
        case .year:
            return "Năm \(calendar.component(.year, from: interval.start))"
        }
    }
}

@MainActor
@Observable
final class StatisticsViewModel {
    var isLoading = false
    var selectedDate = Date()
    var selectedPeriod: StatisticsPeriod = .month
    var selectedType: TransactionType = .expense
    var summary = MonthlySummary(income: 0, expense: 0)
    var categorySpending: [CategorySpending] = []
    var dailySpending: [DailySpending] = []
    var dailyCashFlow: [DailyCashFlow] = []
    var errorMessage: String?

    private let statisticsUseCases: StatisticsUseCases

    init(statisticsUseCases: StatisticsUseCases) {
        self.statisticsUseCases = statisticsUseCases
    }

    var hasChartData: Bool {
        !categorySpending.isEmpty || dailySpending.contains { $0.amount > 0 }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let calendar = AppFormatters.calendar
            guard let interval = selectedPeriod.interval(for: selectedDate, calendar: calendar) else {
                throw DomainError.remoteError("Không xác định được khoảng thời gian.")
            }
            summary = try await statisticsUseCases.summary(for: interval, calendar: calendar)
            if selectedPeriod == .month {
                dailyCashFlow = try await statisticsUseCases.dailyCashFlow(for: interval, calendar: calendar)
            } else {
                dailyCashFlow = []
            }
            categorySpending = try await statisticsUseCases.spendingByCategory(
                for: interval,
                type: selectedType,
                calendar: calendar
            )
            dailySpending = try await statisticsUseCases.spendingTrend(
                period: selectedPeriod.rawValue,
                type: selectedType,
                for: selectedDate,
                calendar: calendar
            )
        } catch {
            errorMessage = error.userMessage
        }
    }

    func moveMonth(_ offset: Int) async {
        let component: Calendar.Component = switch selectedPeriod {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
        selectedDate = AppFormatters.calendar.date(
            byAdding: component,
            value: offset,
            to: selectedDate
        ) ?? selectedDate
        await load()
    }

    func selectPeriod(_ period: StatisticsPeriod, date: Date) async {
        selectedPeriod = period
        selectedDate = date
        await load()
    }

    func selectType(_ type: TransactionType) async {
        guard selectedType != type else { return }
        selectedType = type
        await load()
    }
}
