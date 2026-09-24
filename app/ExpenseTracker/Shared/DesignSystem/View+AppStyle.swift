import SwiftUI

private struct AppCardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadow: Bool

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
            .modifier(AppCardShadowModifier(isEnabled: shadow))
    }
}

private struct AppCardShadowModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.shadow(color: AppTheme.navy.opacity(0.06), radius: 12, y: 5)
        } else {
            content
        }
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

private struct IPadTypographyModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.dynamicTypeSize(.xxxLarge)
        } else {
            content
        }
    }
}

extension View {
    func appCard(
        padding: CGFloat = AppSpacing.large,
        cornerRadius: CGFloat = AppRadius.large,
        shadow: Bool = true
    ) -> some View {
        modifier(
            AppCardModifier(
                padding: padding,
                cornerRadius: cornerRadius,
                shadow: shadow
            )
        )
    }

    func appScreenBackground() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }

    func appFormStyle() -> some View {
        modifier(AppFormStyleModifier())
    }

    func appIPadTypography(isEnabled: Bool) -> some View {
        modifier(IPadTypographyModifier(isEnabled: isEnabled))
    }
}
