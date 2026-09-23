import SwiftUI

struct CategoriesView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: CategoriesViewModel
    @State private var editingCategory: ExpenseCategory?
    @State private var isShowingForm = false
    @State private var successMessage: String?

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeCategoriesViewModel())
    }

    var body: some View {
        List {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Section(type.title) {
                    ForEach(viewModel.categories(of: type)) { category in
                        categoryRow(category)
                    }
                }
            }
        }
        .appFormStyle()
        .navigationTitle("Danh mục")
        .toolbar {
            Button { isShowingForm = true } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Thêm danh mục")
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
        .errorToast(message: $viewModel.errorMessage)
        .successToast(message: $successMessage)
    }

    private func categoryRow(_ category: ExpenseCategory) -> some View {
        Group {
            if category.isEditable {
                Button { editingCategory = category } label: {
                    categoryLabel(category)
                }
                .swipeActions {
                    Button("Xoá", role: .destructive) {
                        Task {
                            if await viewModel.delete(category) {
                                successMessage = "Đã xoá danh mục thành công"
                            }
                        }
                    }
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
}
