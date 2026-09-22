import SwiftUI

struct StatisticsView: View {
    @State var viewModel: StatisticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    MonthSelector(
                        month: viewModel.selectedMonth,
                        previous: { Task { await viewModel.moveMonth(-1) } },
                        next: { Task { await viewModel.moveMonth(1) } }
                    )
                    StatisticsSummaryView(summary: viewModel.summary)
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    MonthlyCashFlowCalendar(
                        month: viewModel.selectedMonth,
                        items: viewModel.dailyCashFlow
                    )
                    statisticsContent
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.xSmall)
                .padding(.bottom, AppSpacing.xxLarge)
            }
            .appScreenBackground()
            .navigationTitle("Thống kê")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var statisticsContent: some View {
        if !viewModel.hasChartData {
            EmptyStateView(
                icon: "chart.bar",
                title: "Chưa có dữ liệu",
                message: "Biểu đồ sẽ xuất hiện khi bạn thêm chi tiêu trong tháng."
            )
            .frame(minHeight: 280)
            .appCard(padding: 0)
        } else {
            DailySpendingChart(items: viewModel.dailySpending)
            CategorySpendingChart(items: viewModel.categorySpending)
        }
    }
}
