import SwiftUI

struct BudgetsView: View {
    private let factory: any ViewModelFactory
    @State private var viewModel: BudgetsViewModel
    @State private var isShowingForm = false
    @State private var editingProgress: BudgetProgress?

    init(factory: any ViewModelFactory) {
        self.factory = factory
        _viewModel = State(initialValue: factory.makeBudgetsViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthSelector(
                month: viewModel.selectedMonth,
                previous: { Task { await viewModel.moveMonth(-1) } },
                next: { Task { await viewModel.moveMonth(1) } },
                selectMonth: { month in
                    Task { await viewModel.selectMonth(month) }
                }
            )
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)

            if viewModel.progress.isEmpty {
                EmptyStateView(
                    icon: "gauge.with.dots.needle.50percent",
                    title: "Chưa có ngân sách",
                    message: "Đặt giới hạn để kiểm soát chi tiêu theo danh mục."
                )
            } else {
                budgetList
            }
        }
        .appScreenBackground()
        .navigationTitle("Ngân sách")
        .toolbar {
            Button { isShowingForm = true } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Thêm ngân sách")
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $isShowingForm, onDismiss: reload) {
            BudgetFormView(
                viewModel: factory.makeBudgetFormViewModel(budget: nil, month: viewModel.selectedMonth)
            )
        }
        .sheet(item: $editingProgress, onDismiss: reload) { progress in
            BudgetFormView(
                viewModel: factory.makeBudgetFormViewModel(budget: progress.budget, month: viewModel.selectedMonth)
            )
        }
        .errorAlert(message: $viewModel.errorMessage)
    }

    private var budgetList: some View {
        List {
            ForEach(viewModel.progress) { progress in
                Button { editingProgress = progress } label: {
                    BudgetRow(progress: progress)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Xoá", role: .destructive) {
                        Task { await viewModel.delete(progress) }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func reload() {
        Task { await viewModel.load() }
    }
}
