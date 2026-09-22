import SwiftUI

private struct FormToolbarModifier: ViewModifier {
    let isSaveDisabled: Bool
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Huỷ") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lưu", action: onSave)
                    .fontWeight(.semibold)
                    .disabled(isSaveDisabled)
            }
        }
    }
}

extension View {
    /// Standard "Huỷ / Lưu" toolbar for create/edit sheets.
    /// `onSave` is responsible for dismissing the sheet once saving succeeds.
    func formToolbar(isSaveDisabled: Bool, onSave: @escaping () -> Void) -> some View {
        modifier(FormToolbarModifier(isSaveDisabled: isSaveDisabled, onSave: onSave))
    }
}
