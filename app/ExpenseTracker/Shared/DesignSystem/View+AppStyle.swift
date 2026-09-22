import SwiftUI

private struct AppCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                AppTheme.elevatedSurface,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 0.5)
            }
            .shadow(color: AppTheme.navy.opacity(0.06), radius: 12, y: 5)
    }
}

private struct AppFormStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .tint(AppTheme.teal)
    }
}

extension View {
    func appCard(
        padding: CGFloat = AppSpacing.large,
        cornerRadius: CGFloat = AppRadius.large
    ) -> some View {
        modifier(AppCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    func appScreenBackground() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }

    func appFormStyle() -> some View {
        modifier(AppFormStyleModifier())
    }
}
