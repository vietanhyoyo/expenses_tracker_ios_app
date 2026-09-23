import SwiftUI

/// Shared card shell for dashboard sections with a consistent header-to-content gap.
struct DashboardSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let detail: String?
    let actionTitle: String?
    let action: (() -> Void)?
    private let content: Content

    init(
        title: String,
        icon: String,
        detail: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AppSectionHeader(title: title, icon: icon, detail: detail)
            content
                .padding(.top, AppSpacing.large)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: AppSpacing.xxxSmall) {
                        Spacer()
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                        Spacer()
                    }
                }
                .font(AppTypography.captionEmphasis)
                .foregroundStyle(AppTheme.teal)
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.medium)
            }
        }
        .appCard()
    }
}
