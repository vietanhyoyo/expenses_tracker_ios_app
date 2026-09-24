import SwiftUI

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    private let factory: any ViewModelFactory
    @State private var viewModel: CategoriesViewModel
    @State private var editingCategory: ExpenseCategory?
    @State private var categoryToDelete: ExpenseCategory?
    @State private var pendingDeleteCategory: ExpenseCategory?
    @State private var pendingReplacementID: UUID?
    @State private var categoriesListID = UUID()
    @State private var isShowingForm = false
    @State private var successMessage: String?

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeCategoriesViewModel())
    }

    var body: some View {
        Group {
            if isPad {
                VStack(spacing: 0) {
                    iPadNavigationHeader
                    categoriesList
                }
                .appScreenBackground()
                .toolbar(.hidden, for: .navigationBar)
            } else {
                categoriesList
                    .navigationTitle("Danh mục")
                    .toolbar {
                        Button { isShowingForm = true } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel("Thêm danh mục")
                    }
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $isShowingForm, onDismiss: reload) {
            CategoryFormView(
                viewModel: factory.makeCategoryFormViewModel(category: nil),
                onSuccess: { successMessage = $0 }
            )
        }
        .sheet(item: $editingCategory, onDismiss: reload) { category in
            CategoryFormView(
                viewModel: factory.makeCategoryFormViewModel(category: category),
                onSuccess: { successMessage = $0 }
            )
        }
        .sheet(item: $categoryToDelete, onDismiss: processPendingDelete) { category in
            CategoryDeleteSheet(
                category: category,
                replacementCategories: viewModel.categories(of: category.type)
                    .filter { $0.id != category.id },
                onConfirm: { replacementID in
                    pendingDeleteCategory = category
                    pendingReplacementID = replacementID
                }
            )
        }
        .errorToast(message: $viewModel.errorMessage)
        .successToast(message: $successMessage)
        .appLoadingOverlay(viewModel.isLoading, message: "Đang tải danh mục…")
    }

    private var categoriesList: some View {
        List {
            Section(TransactionType.income.title) {
                ForEach(viewModel.categories(of: .income), id: \.id) { category in
                    categoryRow(category)
                }
            }
            Section(TransactionType.expense.title) {
                ForEach(viewModel.categories(of: .expense), id: \.id) { category in
                    categoryRow(category)
                }
            }
        }
        .id(categoriesListID)
        .transaction { transaction in
            transaction.animation = nil
        }
        .appFormStyle()
    }

    private var iPadNavigationHeader: some View {
        ZStack {
            Text("Danh mục")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.primary.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quay lại")

                Spacer()

                Button { isShowingForm = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 58, height: 58)
                        .background(AppTheme.elevatedSurface, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(AppTheme.primary.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: AppTheme.navy.opacity(0.1), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Thêm danh mục")
            }
        }
        .padding(.horizontal, AppSpacing.xLarge)
        .frame(height: 76)
        .background(AppTheme.background)
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private func categoryRow(_ category: ExpenseCategory) -> some View {
        Group {
            if category.isEditable {
                Button { editingCategory = category } label: {
                    categoryLabel(category)
                }
                .swipeActions {
                    Button("Xoá", role: .destructive) {
                        categoryToDelete = category
                    }
                    .tint(AppTheme.coral)
                }
            } else {
                categoryLabel(category)
            }
        }
    }

    private func categoryLabel(_ category: ExpenseCategory) -> some View {
        HStack(spacing: AppSpacing.small) {
            AppIconBadge(icon: category.icon, color: category.color, size: 38)
            Text(category.name)
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(.primary)
            Spacer()
            if !category.isEditable {
                Text("Mặc định")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    private func processPendingDelete() {
        guard let category = pendingDeleteCategory,
              let replacementID = pendingReplacementID else {
            return
        }
        pendingDeleteCategory = nil
        pendingReplacementID = nil
        Task {
            if await viewModel.delete(category, replacementID: replacementID) {
                // Recreate the List after the sheet and swipe interaction have
                // completely finished so UICollectionView does not apply a
                // stale section diff to the deleted row.
                categoriesListID = UUID()
                successMessage = "Đã xoá danh mục và chuyển giao dịch thành công"
            }
        }
    }
}

private struct CategoryDeleteSheet: View {
    let category: ExpenseCategory
    let replacementCategories: [ExpenseCategory]
    let onConfirm: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var replacementID: UUID?

    init(
        category: ExpenseCategory,
        replacementCategories: [ExpenseCategory],
        onConfirm: @escaping (UUID) -> Void
    ) {
        self.category = category
        self.replacementCategories = replacementCategories
        self.onConfirm = onConfirm
        _replacementID = State(initialValue: Self.defaultReplacementID(
            for: category,
            in: replacementCategories
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        "Các giao dịch thuộc “\(category.name)” sẽ được chuyển sang danh mục thay thế trước khi xoá."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Section("Danh mục thay thế") {
                    Picker("Chuyển sang", selection: $replacementID) {
                        ForEach(replacementCategories) { replacement in
                            Text(replacement.name).tag(Optional(replacement.id))
                        }
                    }
                    .disabled(replacementCategories.isEmpty)

                    if replacementCategories.isEmpty {
                        Text("Chưa có danh mục cùng loại để thay thế.")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.coral)
                    }
                }
            }
            .appFormStyle()
            .navigationTitle("Xoá danh mục")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xoá", role: .destructive) {
                        guard let replacementID else { return }
                        onConfirm(replacementID)
                        dismiss()
                    }
                    .disabled(replacementID == nil)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private static func defaultReplacementID(
        for category: ExpenseCategory,
        in categories: [ExpenseCategory]
    ) -> UUID? {
        let preferredName = category.type == .income ? "Thu nhập khác" : "Khác"
        if let preferred = categories.first(where: { $0.name == preferredName }) {
            return preferred.id
        }
        return categories.first?.id
    }
}
