import Foundation

struct ExpenseCategory: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    let type: TransactionType
    let colorHex: String
    let isEditable: Bool

    init(
        id: UUID,
        name: String,
        icon: String,
        type: TransactionType,
        colorHex: String? = nil,
        isEditable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.colorHex = colorHex
            ?? Self.defaultPalette[name]
            ?? Self.defaultColorHex(for: type)
        self.isEditable = isEditable
    }

    static func defaultColorHex(for type: TransactionType) -> String {
        type == .income ? "#0092B8" : "#ED4F4A"
    }

    /// Colors of the built-in categories. Also used as a fallback for
    /// categories stored before `colorHex` was persisted.
    static let defaultPalette: [String: String] = [
        "Ăn uống": "#FF5D73",
        "Di chuyển": "#3B82F6",
        "Mua sắm": "#A855F7",
        "Giải trí": "#EC4899",
        "Hoá đơn": "#F59E0B",
        "Sức khoẻ": "#EF4444",
        "Giáo dục": "#14B8A6",
        "Khác": "#64748B",
        "Lương": "#10B981",
        "Thưởng": "#F59E0B",
        "Đầu tư": "#0EA5E9",
        "Thu nhập khác": "#8B5CF6"
    ]
}
