import SwiftUI

struct BudgetFormView: View {
    @State var viewModel: BudgetFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Danh mục") {
                    Picker("Danh mục", selection: $viewModel.categoryID) {
                        ForEach(viewModel.expenseCategories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(Optional(category.id))
                        }
                    }
                }
                Section("Giới hạn mỗi tháng") {
                    VietnameseMoneyTextField(text: $viewModel.amountText)
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .appFormStyle()
            .navigationTitle(viewModel.isEditing ? "Sửa ngân sách" : "Ngân sách mới")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(isSaveDisabled: !viewModel.canSave, onSave: save)
            .task { await viewModel.load() }
        }
    }

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }
}
