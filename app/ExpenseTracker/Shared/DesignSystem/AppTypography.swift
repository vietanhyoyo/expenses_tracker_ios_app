import SwiftUI

enum AppTypography {
    static let heroAmount = Font.system(size: 34, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let cardTitle = Font.system(.subheadline, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyEmphasis = Font.system(.body, design: .rounded).weight(.semibold)
    static let caption = Font.system(.caption, design: .rounded)
    static let captionEmphasis = Font.system(.caption, design: .rounded).weight(.semibold)
}
