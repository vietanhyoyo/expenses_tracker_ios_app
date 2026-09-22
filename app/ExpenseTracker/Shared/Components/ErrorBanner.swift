import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            AppIconBadge(
                icon: "exclamationmark.triangle.fill",
                color: AppTheme.coral,
                size: 36
            )
            VStack(alignment: .leading, spacing: AppSpacing.xxxSmall) {
                Text("Đã xảy ra lỗi")
                    .font(AppTypography.cardTitle)
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.small)
        .background(
            AppTheme.coral.opacity(0.08),
            in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppTheme.coral.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
