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
