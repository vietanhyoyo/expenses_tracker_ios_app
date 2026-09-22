import SwiftUI

struct AppIconBadge: View {
    let icon: String
    var color: Color = AppTheme.teal
    var size: CGFloat = 42
    var backgroundColor: Color? = nil
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 0
    var iconScale: CGFloat = 0.4

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * iconScale, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                backgroundColor ?? color.opacity(0.12),
                in: Circle()
            )
            .overlay {
                if let borderColor, borderWidth > 0 {
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                }
            }
            .accessibilityHidden(true)
    }
}
