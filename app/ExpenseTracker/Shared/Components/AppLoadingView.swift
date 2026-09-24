import SwiftUI

struct AppLoadingView: View {
    let message: String

    init(message: String = "Đang tải dữ liệu…") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .controlSize(.large)
                .tint(AppTheme.teal)

            Text(message)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, AppSpacing.xLarge)
        .padding(.vertical, AppSpacing.large)
        .background(
            AppTheme.elevatedSurface.opacity(0.96),
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

private struct AppLoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        content.overlay {
            if isLoading {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    AppLoadingView(message: message)
                }
                .accessibilityAddTraits(.isModal)
                .transition(.opacity)
            }
        }
    }
}

extension View {
    func appLoadingOverlay(
        _ isLoading: Bool,
        message: String = "Đang tải dữ liệu…"
    ) -> some View {
        modifier(AppLoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
