import SwiftUI

struct AppSectionHeader: View {
    let title: String
    var icon: String?
    var detail: String?

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.teal)
            }
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(.primary)
            Spacer(minLength: AppSpacing.xSmall)
            if let detail {
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
