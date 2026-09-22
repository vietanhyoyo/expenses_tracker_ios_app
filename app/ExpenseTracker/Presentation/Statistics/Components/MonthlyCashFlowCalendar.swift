import SwiftUI

struct MonthlyCashFlowCalendar: View {
    let month: Date
    let items: [DailyCashFlow]

    private static let dayCellHeight: CGFloat = 66
    private static let weekdayTitles = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.xxxSmall),
        count: 7
    )
    private let calendar = Calendar.current

    var body: some View {
        // Computed once per render instead of once per day cell.
        let cashFlowByDay = makeCashFlowByDay()

        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            AppSectionHeader(title: "Lịch thu chi", icon: "calendar")

            LazyVGrid(columns: columns, spacing: AppSpacing.xSmall) {
                ForEach(Self.weekdayTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date, item: cashFlowByDay[calendar.startOfDay(for: date)])
                    } else {
                        Color.clear
                            .frame(height: Self.dayCellHeight)
                            .accessibilityHidden(true)
                    }
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

    /// Days of the month padded with `nil` so the grid starts on Monday
    /// and ends on a full week.
    private var dayCells: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let days = calendar.range(of: .day, in: .month, for: month)
        else {
            return []
        }

        let firstDay = calendar.startOfDay(for: monthInterval.start)
        let leadingEmptyDays = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var cells = [Date?](repeating: nil, count: leadingEmptyDays)
        cells.append(contentsOf: days.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        })
        let trailingEmptyDays = (7 - cells.count % 7) % 7
        cells.append(contentsOf: [Date?](repeating: nil, count: trailingEmptyDays))
        return cells
    }

    private func makeCashFlowByDay() -> [Date: DailyCashFlow] {
        Dictionary(
            items.map { (calendar.startOfDay(for: $0.date), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func dayCell(for date: Date, item: DailyCashFlow?) -> some View {
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 3) {
            Text(date.formatted(.dateTime.day()))
                .font(.caption.weight(isToday ? .bold : .medium))
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .frame(width: 24, height: 24)
                .background(isToday ? AppTheme.teal : Color.clear, in: Circle())

            Spacer(minLength: 0)

            amountLine(prefix: "+", amount: item?.income ?? 0, color: TransactionType.income.color)
            amountLine(prefix: "−", amount: item?.expense ?? 0, color: TransactionType.expense.color)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, AppSpacing.xxxSmall)
        .frame(maxWidth: .infinity, minHeight: Self.dayCellHeight, alignment: .top)
        .background(
            AppTheme.navy.opacity(item == nil ? 0 : 0.035),
            in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                .stroke(
                    isToday ? AppTheme.teal.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: date, item: item))
    }

    private func amountLine(prefix: String, amount: Decimal, color: Color) -> some View {
        Text(amount > 0 ? prefix + AppFormatters.compactMoney(amount.doubleValue) : " ")
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity)
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

    private func accessibilityLabel(for date: Date, item: DailyCashFlow?) -> String {
        let dateText = date.formatted(.dateTime.day().month().year())
        guard let item else { return "\(dateText), không có giao dịch" }
        return "\(dateText), thu \(AppFormatters.money(item.income)), chi \(AppFormatters.money(item.expense))"
    }
}
