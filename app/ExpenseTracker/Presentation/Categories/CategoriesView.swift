import SwiftUI

struct CategoriesView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: CategoriesViewModel
    @State private var editingCategory: ExpenseCategory?
    @State private var isShowingForm = false

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
            CategoryFormView(viewModel: factory.makeCategoryFormViewModel(category: nil))
        }
        .sheet(item: $editingCategory, onDismiss: reload) { category in
            CategoryFormView(viewModel: factory.makeCategoryFormViewModel(category: category))
        }
        .errorAlert(message: $viewModel.errorMessage)
    }

    private func categoryRow(_ category: ExpenseCategory) -> some View {
        Button { editingCategory = category } label: {
            HStack(spacing: AppSpacing.small) {
                AppIconBadge(
                    icon: category.icon,
                    color: category.color,
                    size: 38
                )
                Text(category.name)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 2)
        }
        .swipeActions {
            Button("Xoá", role: .destructive) {
                Task { await viewModel.delete(category) }
            }
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}
