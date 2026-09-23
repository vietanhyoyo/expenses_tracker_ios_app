import SwiftUI

extension View {
    func errorAlert(message: Binding<String?>) -> some View {
        alert(
            "Không thể thực hiện",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

private struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(AppTheme.success, in: Capsule(style: .continuous))
        .shadow(color: AppTheme.success.opacity(0.28), radius: 12, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

private struct SuccessToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    SuccessToast(message: message)
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.top, AppSpacing.small)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: message) {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            guard !Task.isCancelled else { return }
                            self.message = nil
                        }
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: message)
    }
}

extension View {
    /// Displays a short-lived success notification for completed API actions.
    func successToast(message: Binding<String?>) -> some View {
        modifier(SuccessToastModifier(message: message))
    }
}
