import Foundation

enum AppFormatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let compactDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "'Tháng' M, yyyy"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    static func money(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "\(value) ₫"
    }

    static func decimal(from text: String) -> Decimal? {
        let digits = text.filter { $0.isNumber || $0 == "," || $0 == "." }
        if digits.isEmpty { return nil }
        let normalized = digits.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func vietnameseMoneyInput(from value: Decimal) -> String {
        vietnameseMoneyInput(NSDecimalNumber(decimal: value).stringValue)
    }

    static func vietnameseMoneyInput(_ text: String) -> String {
        let digits = text.compactMap(\.wholeNumberValue).map(String.init).joined()
        guard !digits.isEmpty else { return "" }

        let significantDigits = digits.drop(while: { $0 == "0" })
        let normalized = significantDigits.isEmpty ? "0" : String(significantDigits)
        let characters = Array(normalized)
        var groups: [String] = []
        var endIndex = characters.count

        while endIndex > 0 {
            let startIndex = max(0, endIndex - 3)
            groups.append(String(characters[startIndex..<endIndex]))
            endIndex = startIndex
        }

        return groups.reversed().joined(separator: ".")
    }

    static func compactMoney(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = NSNumber(value: value / 1_000_000)
            return "\(compactDecimal.string(from: millions) ?? "0")tr"
        }
        if value >= 1_000 {
            return "\(Int((value / 1_000).rounded()))k"
        }
        return String(format: "%.0f", value)
    }
}
