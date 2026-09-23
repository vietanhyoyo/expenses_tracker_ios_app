import SwiftUI

struct StatisticsView: View {
    @State var viewModel: StatisticsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    StatisticsPeriodSelector(
                        period: viewModel.selectedPeriod,
                        date: viewModel.selectedDate,
                        previous: { Task { await viewModel.moveMonth(-1) } },
                        next: { Task { await viewModel.moveMonth(1) } },
                        selectPeriod: { period, date in
                            Task { await viewModel.selectPeriod(period, date: date) }
                        }
                    )
                    StatisticsSummaryView(
                        summary: viewModel.summary,
                        selectedType: viewModel.selectedType,
                        onSelect: { type in
                            Task { await viewModel.selectType(type) }
                        }
                    )
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    statisticsContent
                    if viewModel.selectedPeriod == .month {
                        MonthlyCashFlowCalendar(
                            month: viewModel.selectedDate,
                            items: viewModel.dailyCashFlow
                        )
                    }
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
                message: "Biểu đồ sẽ xuất hiện khi bạn có \(viewModel.selectedType.title.lowercased()) trong khoảng thời gian đã chọn."
            )
            .frame(minHeight: 280)
            .appCard(padding: 0)
        } else {
            DailySpendingChart(
                items: viewModel.dailySpending,
                period: viewModel.selectedPeriod,
                transactionType: viewModel.selectedType
            )
            CategorySpendingChart(
                items: viewModel.categorySpending,
                transactionType: viewModel.selectedType
            )
        }
    }
}
