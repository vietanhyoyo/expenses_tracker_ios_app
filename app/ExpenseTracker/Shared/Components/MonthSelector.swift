import SwiftUI

struct MonthSelector: View {
    let month: Date
    let previous: () -> Void
    let next: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            monthButton(icon: "chevron.left", label: "Tháng trước", action: previous)
            Spacer()
            VStack(spacing: 2) {
                Text("THỜI GIAN")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text(AppFormatters.monthYear.string(from: month))
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(.primary)
            }
            Spacer()
            monthButton(icon: "chevron.right", label: "Tháng sau", action: next)
        }
        .padding(AppSpacing.xSmall)
        .background(
            AppTheme.elevatedSurface,
            in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
    }

    private func monthButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppIconBadge(icon: icon, color: AppTheme.teal, size: 38)
        }
        .accessibilityLabel(label)
    }
}
