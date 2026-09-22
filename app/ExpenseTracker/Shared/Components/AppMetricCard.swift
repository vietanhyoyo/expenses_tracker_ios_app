import SwiftUI

struct AppMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                AppIconBadge(icon: icon, color: color, size: 34)
                Spacer()
            }
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: AppSpacing.medium, cornerRadius: AppRadius.large)
    }
}
