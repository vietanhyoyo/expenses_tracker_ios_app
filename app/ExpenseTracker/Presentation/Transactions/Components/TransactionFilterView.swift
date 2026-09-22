import SwiftUI

struct TransactionFilterView: View {
    @Bindable var viewModel: TransactionListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                categorySection
                accountSection
                sortSection
            }
            .appFormStyle()
            .navigationTitle("Bộ lọc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đặt lại") { viewModel.clearFilters() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var typeSection: some View {
        Section("Loại giao dịch") {
            Picker("Loại", selection: $viewModel.selectedType) {
                Text("Tất cả").tag(nil as TransactionType?)
                ForEach(TransactionType.allCases, id: \.self) {
                    Text($0.title).tag(Optional($0))
                }
            }
        }
    }

    private var categorySection: some View {
        Section("Danh mục") {
            Picker("Danh mục", selection: $viewModel.selectedCategoryID) {
                Text("Tất cả").tag(nil as UUID?)
                ForEach(viewModel.sortedCategories) {
                    Label($0.name, systemImage: $0.icon).tag(Optional($0.id))
                }
            }
        }
    }

    private var accountSection: some View {
        Section("Tài khoản") {
            Picker("Tài khoản", selection: $viewModel.selectedAccountID) {
                Text("Tất cả").tag(nil as UUID?)
                ForEach(viewModel.sortedAccounts) {
                    Text($0.name).tag(Optional($0.id))
                }
            }
        }
    }

    private var sortSection: some View {
        Section("Sắp xếp") {
            Picker("Sắp xếp", selection: $viewModel.sort) {
                ForEach(TransactionSort.allCases, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
        }
    }
}
