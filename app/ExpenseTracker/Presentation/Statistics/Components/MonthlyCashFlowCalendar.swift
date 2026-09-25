import SwiftUI

/// Immutable, pre-rendered data for the monthly cash-flow calendar.
///
/// Keeping date and money formatting out of `body` is important here: SwiftUI may
/// evaluate the calendar body many times while the surrounding statistics screen
/// scrolls or updates. This type is also the boundary that can be moved into a
/// standalone Swift Package later without coupling the renderer to the view model.
struct CashFlowCalendarData: Equatable, Sendable {
    struct Cell: Identifiable, Equatable, Sendable {
        let id: Int
        let date: Date?
        let dayNumber: String
        let incomeText: String
        let expenseText: String
        let accessibilityLabel: String
        let isToday: Bool
        let hasCashFlow: Bool
        let isEmpty: Bool

        static func empty(id: Int) -> Cell {
            Cell(
                id: id,
                date: nil,
                dayNumber: "",
                incomeText: "",
                expenseText: "",
                accessibilityLabel: "",
                isToday: false,
                hasCashFlow: false,
                isEmpty: true
            )
        }
    }

    let cells: [Cell]

    static let empty = CashFlowCalendarData(cells: [])

    init(
        month: Date,
        items: [DailyCashFlow],
        calendar: Calendar = AppFormatters.calendar
    ) {
        let cashFlowByDay = Dictionary(
            items.map { (calendar.startOfDay(for: $0.date), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let days = calendar.range(of: .day, in: .month, for: month)
        else {
            cells = []
            return
        }

        let firstDay = calendar.startOfDay(for: monthInterval.start)
        let leadingEmptyDays = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var result = (0..<leadingEmptyDays).map(Cell.empty)

        for day in days {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: date)
            let item = cashFlowByDay[dayStart]
            let dateText = AppFormatters.dateString(date)
            let income = item?.income ?? 0
            let expense = item?.expense ?? 0

            result.append(
                Cell(
                    id: result.count,
                    date: date,
                    dayNumber: String(day),
                    incomeText: income > 0 ? "+" + AppFormatters.compactMoney(income.doubleValue) : " ",
                    expenseText: expense > 0 ? "−" + AppFormatters.compactMoney(expense.doubleValue) : " ",
                    accessibilityLabel: item.map {
                        "\(dateText), thu \(AppFormatters.money($0.income)), chi \(AppFormatters.money($0.expense))"
                    } ?? "\(dateText), không có giao dịch",
                    isToday: calendar.isDateInToday(date),
                    hasCashFlow: item != nil,
                    isEmpty: false
                )
            )
        }

        let trailingEmptyDays = (7 - result.count % 7) % 7
        let firstTrailingEmptyID = result.count
        result.append(contentsOf: (0..<trailingEmptyDays).map { Cell.empty(id: firstTrailingEmptyID + $0) })
        cells = result
    }

    private init(cells: [Cell]) {
        self.cells = cells
    }
}

struct MonthlyCashFlowCalendar: View, Equatable {
    let data: CashFlowCalendarData

    fileprivate static let dayCellHeight: CGFloat = 66
    private static let weekdayTitles = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    private static let columns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.xxxSmall),
        count: 7
    )

    init(data: CashFlowCalendarData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            AppSectionHeader(title: "Lịch thu chi", icon: "calendar")

            LazyVGrid(columns: Self.columns, spacing: AppSpacing.xSmall) {
                ForEach(Self.weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(data.cells) { cell in
                    CashFlowCalendarDayCell(cell: cell)
                }
            }

            HStack(spacing: AppSpacing.medium) {
                legend(color: TransactionType.income.color, title: TransactionType.income.title)
                legend(color: TransactionType.expense.color, title: TransactionType.expense.title)
            }
            .frame(maxWidth: .infinity)
        }
        .appCard(padding: AppSpacing.medium)
    }

    private func legend(color: Color, title: String) -> some View {
        HStack(spacing: AppSpacing.xxSmall) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CashFlowCalendarDayCell: View, Equatable {
    let cell: CashFlowCalendarData.Cell

    var body: some View {
        Group {
            if cell.isEmpty {
                Color.clear
                    .frame(height: MonthlyCashFlowCalendar.dayCellHeight)
                    .accessibilityHidden(true)
            } else {
                VStack(spacing: 3) {
                    Text(verbatim: cell.dayNumber)
                        .font(.caption.weight(cell.isToday ? .bold : .medium))
                        .foregroundStyle(cell.isToday ? Color.white : Color.primary)
                        .frame(width: 24, height: 24)
                        .background(cell.isToday ? AppTheme.teal : Color.clear, in: Circle())

                    Spacer(minLength: 0)

                    amountLine(cell.incomeText, color: TransactionType.income.color)
                    amountLine(cell.expenseText, color: TransactionType.expense.color)
                }
                .padding(.horizontal, 2)
                .padding(.vertical, AppSpacing.xxxSmall)
                .frame(
                    maxWidth: .infinity,
                    minHeight: MonthlyCashFlowCalendar.dayCellHeight,
                    alignment: .top
                )
                .background(
                    AppTheme.navy.opacity(cell.hasCashFlow ? 0.035 : 0),
                    in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .stroke(
                            cell.isToday ? AppTheme.teal.opacity(0.25) : Color.clear,
                            lineWidth: 1
                        )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(cell.accessibilityLabel)
            }
        }
    }

    private func amountLine(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity)
    }
}
