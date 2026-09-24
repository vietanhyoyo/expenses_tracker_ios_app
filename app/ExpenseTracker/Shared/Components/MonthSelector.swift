import SwiftUI

/// A date input with one explicit presentation format across the app.
struct AppDatePickerField: View {
    let title: String
    @Binding var date: Date

    @State private var draftDate: Date
    @State private var isShowingPicker = false

    init(title: String, date: Binding<Date>) {
        self.title = title
        _date = date
        _draftDate = State(initialValue: date.wrappedValue)
    }

    var body: some View {
        Button {
            draftDate = date
            isShowingPicker = true
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(AppFormatters.dateString(date))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(AppFormatters.dateString(date))
        .sheet(isPresented: $isShowingPicker) {
            NavigationStack {
                DatePicker(
                    title,
                    selection: $draftDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, AppFormatters.locale)
                .environment(\.calendar, AppFormatters.calendar)
                .padding(.horizontal, AppSpacing.small)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Huỷ") { isShowingPicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Áp dụng") {
                            date = draftDate
                            isShowingPicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationBackground(AppTheme.elevatedSurface)
            .presentationDragIndicator(.visible)
        }
    }
}

struct MonthSelector: View {
    let month: Date
    let previous: () -> Void
    let next: () -> Void
    let selectMonth: (Date) -> Void

    @State private var isShowingMonthPicker = false
    @State private var draftMonth: Date

    init(
        month: Date,
        previous: @escaping () -> Void,
        next: @escaping () -> Void,
        selectMonth: @escaping (Date) -> Void = { _ in }
    ) {
        self.month = month
        self.previous = previous
        self.next = next
        self.selectMonth = selectMonth
        _draftMonth = State(initialValue: month)
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            monthButton(icon: "chevron.left", label: "Tháng trước", action: previous)
            Spacer()
            Button {
                draftMonth = month
                isShowingMonthPicker = true
            } label: {
                VStack(spacing: 2) {
                    Text("THỜI GIAN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    HStack(spacing: AppSpacing.xxSmall) {
                        Text(AppFormatters.monthYear.string(from: month))
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .padding(.horizontal, AppSpacing.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chọn tháng")
            Spacer()
            monthButton(icon: "chevron.right", label: "Tháng sau", action: next)
        }
        .padding(.vertical, AppSpacing.xxxSmall)
        .sheet(isPresented: $isShowingMonthPicker) {
            MonthPickerSheet(
                month: $draftMonth,
                onConfirm: {
                    isShowingMonthPicker = false
                    selectMonth(draftMonth)
                }
            )
        }
    }

    private func monthButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.primary.opacity(0.09), in: Circle())
        }
        .accessibilityLabel(label)
    }
}

private struct MonthPickerSheet: View {
    @Binding var month: Date
    let onConfirm: () -> Void

    private let calendar = AppFormatters.calendar
    private let monthNames = [
        "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
        "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
    ]

    private var selectedMonth: Int {
        calendar.component(.month, from: month)
    }

    private var selectedYear: Int {
        calendar.component(.year, from: month)
    }

    private var years: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        let lowerBound = min(currentYear - 10, selectedYear - 2)
        let upperBound = max(currentYear + 2, selectedYear + 2)
        return Array(lowerBound...upperBound)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thời gian") {
                    Picker("Tháng", selection: monthBinding) {
                        ForEach(1...12, id: \.self) { value in
                            Text(monthNames[value - 1]).tag(value)
                        }
                    }

                    Picker("Năm", selection: yearBinding) {
                        ForEach(years, id: \.self) { value in
                            Text(String(value)).tag(value)
                        }
                    }
                }

                Section {
                    Text(AppFormatters.monthYear.string(from: month))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .appFormStyle()
            .navigationTitle("Chọn tháng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Áp dụng", action: onConfirm)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .environment(\.locale, AppFormatters.locale)
        .environment(\.calendar, AppFormatters.calendar)
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: { selectedMonth },
            set: { updateMonth(month: $0, year: selectedYear) }
        )
    }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { selectedYear },
            set: { updateMonth(month: selectedMonth, year: $0) }
        )
    }

    private func updateMonth(month: Int, year: Int) {
        var components = calendar.dateComponents([.year, .month], from: self.month)
        components.year = year
        components.month = month
        components.day = 1
        self.month = calendar.date(from: components) ?? self.month
    }
}

struct StatisticsPeriodSelector: View {
    let period: StatisticsPeriod
    let date: Date
    let previous: () -> Void
    let next: () -> Void
    let selectPeriod: (StatisticsPeriod, Date) -> Void

    @State private var isShowingPicker = false
    @State private var draftPeriod: StatisticsPeriod
    @State private var draftDate: Date

    init(
        period: StatisticsPeriod,
        date: Date,
        previous: @escaping () -> Void,
        next: @escaping () -> Void,
        selectPeriod: @escaping (StatisticsPeriod, Date) -> Void
    ) {
        self.period = period
        self.date = date
        self.previous = previous
        self.next = next
        self.selectPeriod = selectPeriod
        _draftPeriod = State(initialValue: period)
        _draftDate = State(initialValue: date)
    }

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            periodButton(icon: "chevron.left", label: "Khoảng trước", action: previous)
            Spacer()
            Button {
                draftPeriod = period
                draftDate = date
                isShowingPicker = true
            } label: {
                VStack(spacing: 2) {
                    Text("THỜI GIAN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)
                    HStack(spacing: AppSpacing.xxSmall) {
                        Text(period.displayValue(for: date, calendar: AppFormatters.calendar))
                            .font(
                                period == .week
                                    ? .system(size: 15, weight: .semibold, design: .rounded)
                                    : AppTypography.cardTitle
                            )
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(period == .week ? 2 : 1)
                            .minimumScaleFactor(period == .week ? 0.8 : 1)
                            .fixedSize(horizontal: false, vertical: period == .week)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                }
                .padding(.horizontal, AppSpacing.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chọn khoảng thời gian")
            Spacer()
            periodButton(icon: "chevron.right", label: "Khoảng sau", action: next)
        }
        .padding(.vertical, AppSpacing.xxxSmall)
        .sheet(isPresented: $isShowingPicker) {
            StatisticsPeriodPickerSheet(
                period: $draftPeriod,
                date: $draftDate,
                onConfirm: {
                    isShowingPicker = false
                    selectPeriod(draftPeriod, draftDate)
                }
            )
        }
    }

    private func periodButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.primary.opacity(0.09), in: Circle())
        }
        .accessibilityLabel(label)
    }
}

private struct StatisticsPeriodPickerSheet: View {
    @Binding var period: StatisticsPeriod
    @Binding var date: Date
    let onConfirm: () -> Void

    private let calendar = AppFormatters.calendar
    private let monthNames = [
        "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
        "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
    ]

    private var selectedMonth: Int {
        calendar.component(.month, from: date)
    }

    private var selectedYear: Int {
        calendar.component(.year, from: date)
    }

    private var years: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        let lowerBound = min(currentYear - 10, selectedYear - 2)
        let upperBound = max(currentYear + 2, selectedYear + 2)
        return Array(lowerBound...upperBound)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Loại thời gian") {
                    Picker("Xem theo", selection: $period) {
                        ForEach(StatisticsPeriod.allCases, id: \.self) { value in
                            Text(value.title).tag(value)
                        }
                    }
                }

                Section("Chọn thời gian") {
                    if period == .week {
                        AppDatePickerField(title: "Ngày trong tuần", date: $date)
                    } else if period == .year {
                        Picker("Năm", selection: yearBinding) {
                            ForEach(years, id: \.self) { value in
                                Text(String(value)).tag(value)
                            }
                        }
                    } else {
                        Picker("Tháng", selection: monthBinding) {
                            ForEach(1...12, id: \.self) { value in
                                Text(monthNames[value - 1]).tag(value)
                            }
                        }
                        Picker("Năm", selection: yearBinding) {
                            ForEach(years, id: \.self) { value in
                                Text(String(value)).tag(value)
                            }
                        }
                    }
                }

                Section {
                    Text(period.displayValue(for: date, calendar: calendar))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .appFormStyle()
            .navigationTitle("Chọn thời gian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Áp dụng", action: onConfirm)
                        .fontWeight(.semibold)
                }
            }
        }
        // Give the period picker enough vertical space for all sections and
        // the selected-period preview without clipping the bottom content.
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
        .environment(\.locale, AppFormatters.locale)
        .environment(\.calendar, AppFormatters.calendar)
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: { selectedMonth },
            set: { updateDate(month: $0, year: selectedYear) }
        )
    }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { selectedYear },
            set: { updateDate(month: selectedMonth, year: $0) }
        )
    }

    private func updateDate(month: Int, year: Int) {
        var components = calendar.dateComponents([.year, .month], from: date)
        components.year = year
        components.month = month
        components.day = 1
        date = calendar.date(from: components) ?? date
    }
}
