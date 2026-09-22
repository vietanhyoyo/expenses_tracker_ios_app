import SwiftUI

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            AppIconBadge(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
