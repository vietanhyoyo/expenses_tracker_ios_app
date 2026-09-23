import SwiftUI

struct DashboardBudgetCard: View {
    let items: [BudgetProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            AppSectionHeader(
                title: "Ngân sách tháng",
                icon: "gauge.with.dots.needle.50percent"
            )
            Divider()
            ForEach(items.prefix(3)) { progress in
                BudgetProgressRow(progress: progress)
            }
        }
    }
}

private struct BudgetProgressRow: View {
    let progress: BudgetProgress

    private var color: Color {
        progress.status.color
    }

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            HStack(spacing: AppSpacing.xSmall) {
                AppIconBadge(
                    icon: progress.category.icon,
                    color: progress.category.color,
                    size: 34
                )
                Text(progress.category.name)
                    .font(AppTypography.cardTitle)
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
        }
    }
}
