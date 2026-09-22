import SwiftUI

struct DashboardCompactEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            AppIconBadge(icon: icon, color: .secondary, size: 38)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}
