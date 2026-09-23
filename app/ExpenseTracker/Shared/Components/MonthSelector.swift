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
        .padding(.vertical, AppSpacing.xxxSmall)
    }

    private func monthButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.primary.opacity(0.09), in: Circle())
        }
        .accessibilityLabel(label)
    }
}
