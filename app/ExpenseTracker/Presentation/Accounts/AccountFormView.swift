import SwiftUI

struct AccountFormView: View {
    @State var viewModel: AccountFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Tên tài khoản") {
                    TextField("Ví dụ: Tài khoản ngân hàng", text: $viewModel.name)
                }
                Section("Số dư ban đầu") {
                    VietnameseMoneyTextField(text: $viewModel.initialBalanceText)
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .appFormStyle()
            .navigationTitle(viewModel.isEditing ? "Sửa tài khoản" : "Tài khoản mới")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(isSaveDisabled: !viewModel.canSave, onSave: save)
        }
    }

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }
}
