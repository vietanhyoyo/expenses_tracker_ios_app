import SwiftUI

/// A soft, rounded divider used to give the dashboard sections more breathing room.
struct DashboardPillDivider: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(AppTheme.primary.opacity(0.07))
            .frame(maxWidth: .infinity)
            .frame(height: 8)
            .accessibilityHidden(true)
    }
}
