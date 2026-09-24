import SwiftUI

struct TransactionFormView: View {
    @State var viewModel: TransactionFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirmation = false
    private let onSuccess: ((String) -> Void)?

    init(
        viewModel: TransactionFormViewModel,
        onSuccess: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSuccess = onSuccess
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TransactionTypePicker(selection: $viewModel.type)
                        .disabled(viewModel.isEditing)
                        .onChange(of: viewModel.type) { _, _ in
                            viewModel.typeChanged()
                        }

                    AmountTextField(
                        text: $viewModel.amountText,
                        accentColor: viewModel.type.color
                    )
                }
                .listRowInsets(EdgeInsets(
                    top: AppSpacing.xSmall,
                    leading: 0,
                    bottom: AppSpacing.xSmall,
                    trailing: 0
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
                    AppDatePickerField(title: "Ngày", date: $viewModel.date)
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActions
            }
            .navigationTitle(viewModel.isEditing ? "Sửa giao dịch" : "Thêm giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .background(
                                AppTheme.surface,
                                in: Circle()
                            )
                    }
                    .accessibilityLabel("Quay lại")
                }

                if viewModel.isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.coral)
                                .frame(width: 34, height: 34)
                                .background(
                                    AppTheme.coral.opacity(0.1),
                                    in: Circle()
                                )
                        }
                        .disabled(viewModel.isSaving)
                        .opacity(viewModel.isSaving ? 0.5 : 1)
                        .accessibilityLabel("Xoá giao dịch")
                        .accessibilityHint("Mở hộp thoại xác nhận xoá")
                    }
                }
            }
            .task { await viewModel.load() }
            .alert("Xoá giao dịch?", isPresented: $isShowingDeleteConfirmation) {
                Button("Huỷ", role: .cancel) {}
                Button("Xoá", role: .destructive) {
                    Task {
                        if await viewModel.delete() {
                            onSuccess?("Đã xoá giao dịch thành công")
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Giao dịch này sẽ bị xoá vĩnh viễn và không thể hoàn tác.")
            }
        }
        .tint(AppTheme.teal)
    }

    private func save() {
        Task {
            if await viewModel.save() {
                let message: String
                if viewModel.isEditing {
                    message = "Đã cập nhật giao dịch thành công"
                } else {
                    message = viewModel.type == .income
                        ? "Đã thêm khoản thu thành công"
                        : "Đã thêm khoản chi thành công"
                }
                onSuccess?(message)
                dismiss()
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: AppSpacing.small) {
            Button {
                dismiss()
            } label: {
                Label("Huỷ", systemImage: "xmark")
                    .font(AppTypography.bodyEmphasis)
                    .frame(width: 108, height: 50)
                    .foregroundStyle(.secondary)
                    .background(
                        AppTheme.surface,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                        .stroke(AppTheme.separator, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            Button(action: save) {
                Label("Lưu giao dịch", systemImage: "checkmark")
                    .font(AppTypography.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.white)
                    .background(
                        AppTheme.teal,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: AppTheme.teal.opacity(viewModel.canSave ? 0.24 : 0),
                        radius: 8,
                        y: 4
                    )
            }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1 : 0.42)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSave)
    }
}

private struct TransactionFormSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.height(700)])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

extension View {
    func transactionFormSheetPresentation() -> some View {
        modifier(TransactionFormSheetPresentationModifier())
    }
}

private struct TransactionTypePicker: View {
    @Binding var selection: TransactionType

    var body: some View {
        HStack(spacing: AppSpacing.xxSmall) {
            typeButton(for: .income, icon: "arrow.down.left")
            typeButton(for: .expense, icon: "arrow.up.right")
        }
        .padding(AppSpacing.xxSmall)
        .background(
            AppTheme.surface,
            in: Capsule(style: .continuous)
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
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
                .frame(height: 52)
                .foregroundStyle(isSelected ? Color.white : color)
                .background(
                    isSelected ? color : color.opacity(0.09),
                    in: Capsule(style: .continuous)
                )
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(
                            isSelected ? color : color.opacity(0.18),
                            lineWidth: isSelected ? 0 : 0.8
                        )
                }
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
