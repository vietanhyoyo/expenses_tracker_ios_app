import SwiftUI

struct TransactionFormView: View {
    @State var viewModel: TransactionFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TransactionTypePicker(selection: $viewModel.type)
                        .onChange(of: viewModel.type) { _, _ in
                            viewModel.typeChanged()
                        }
                        .padding(.horizontal, AppSpacing.xxxSmall)

                    AmountTextField(
                        text: $viewModel.amountText,
                        accentColor: viewModel.type.color
                    )
                }
                .listRowInsets(EdgeInsets(
                    top: AppSpacing.xSmall,
                    leading: AppSpacing.medium,
                    bottom: AppSpacing.xSmall,
                    trailing: AppSpacing.medium
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                Section("Thông tin") {
                    Picker("Danh mục", selection: $viewModel.categoryID) {
                        ForEach(viewModel.availableCategories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(Optional(category.id))
                        }
                    }
                    Picker("Tài khoản", selection: $viewModel.accountID) {
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    DatePicker("Ngày", selection: $viewModel.date, displayedComponents: [.date])
                    TextField("Ghi chú (không bắt buộc)", text: $viewModel.note, axis: .vertical)
                }
                if let error = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: error)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .appFormStyle()
            .navigationTitle(viewModel.isEditing ? "Sửa giao dịch" : "Thêm giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(isSaveDisabled: !viewModel.canSave, onSave: save)
            .task { await viewModel.load() }
        }
        .tint(AppTheme.teal)
    }

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }
}

private struct TransactionTypePicker: View {
    @Binding var selection: TransactionType

    var body: some View {
        HStack(spacing: AppSpacing.xxSmall) {
            typeButton(for: .income, icon: "arrow.down.left")
            typeButton(for: .expense, icon: "arrow.up.right")
        }
        .padding(AppSpacing.xxxSmall)
        .background(
            AppTheme.navy.opacity(0.055),
            in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }

    private func typeButton(for type: TransactionType, icon: String) -> some View {
        let isSelected = selection == type
        let color = type.color

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = type
            }
        } label: {
            Label(type.title, systemImage: icon)
                .font(AppTypography.bodyEmphasis)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .background(
                    isSelected ? color : Color.clear,
                    in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                )
                .shadow(
                    color: isSelected ? color.opacity(0.2) : .clear,
                    radius: 6,
                    y: 3
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
