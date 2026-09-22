import Foundation

extension Date {
    func addingMonths(_ value: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: value, to: self) ?? self
    }
}
