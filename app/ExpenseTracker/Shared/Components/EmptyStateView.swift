import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            AppIconBadge(icon: icon, color: AppTheme.teal, size: 62)
            VStack(spacing: AppSpacing.xxSmall) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
