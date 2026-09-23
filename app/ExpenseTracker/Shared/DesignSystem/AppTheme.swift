import SwiftUI
import UIKit

enum AppTheme {
    static let primary = Color(red: 76 / 255, green: 89 / 255, blue: 215 / 255)
    static let primaryDark = Color(red: 48 / 255, green: 58 / 255, blue: 158 / 255)

    // Compatibility aliases for existing views while the design token remains centralized.
    static let teal = primary
    static let tealDark = primaryDark
    static let navy = Color(red: 0.07, green: 0.14, blue: 0.22)
    static let coral = Color(red: 0.93, green: 0.31, blue: 0.29)
    static let gold = Color(red: 0.94, green: 0.62, blue: 0.12)
    static let violet = Color(red: 0.42, green: 0.35, blue: 0.82)

    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .systemBackground)
    static let separator = Color(uiColor: .separator).opacity(0.45)

    static let heroGradient = LinearGradient(
        colors: [navy, tealDark, teal.opacity(0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0

        guard value.count == 6, Scanner(string: value).scanHexInt64(&rgb) else {
            self = .gray
            return
        }

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    var hexRGB: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#808080"
        }

        // Extended-range (wide gamut) components can fall outside 0...1.
        let channel = { (value: CGFloat) in Int(round(min(max(value, 0), 1) * 255)) }
        return String(format: "#%02X%02X%02X", channel(red), channel(green), channel(blue))
    }
}
