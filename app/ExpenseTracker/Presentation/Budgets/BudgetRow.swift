import SwiftUI

struct BudgetRow: View {
    let progress: BudgetProgress

    private var color: Color {
        progress.status.color
    }

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.small) {
                AppIconBadge(icon: progress.category.icon, color: progress.category.color, size: 38)
                Text(progress.category.name)
                    .font(AppTypography.bodyEmphasis)
                Spacer()
                Text("\(progress.percentage)%")
                    .font(AppTypography.captionEmphasis)
                    .foregroundStyle(color)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxxSmall)
                    .background(color.opacity(0.11), in: Capsule())
            }
            ProgressView(value: progress.progressValue)
                .tint(color)
            HStack {
                Text("Đã dùng \(AppFormatters.money(progress.spent))")
                Spacer()
                Text("/ \(AppFormatters.money(progress.budget.amount))")
            }
            .font(AppTypography.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.xxxSmall)
    }
}
