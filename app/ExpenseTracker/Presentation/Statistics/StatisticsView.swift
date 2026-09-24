import SwiftUI

struct StatisticsView: View {
    private enum LayoutMode: Equatable {
        case iPhonePortrait
        case iPadPortrait
        case iPadLandscape
    }

    @State var viewModel: StatisticsViewModel

    var body: some View {
        GeometryReader { proxy in
            let mode = layoutMode(for: proxy.size)

            NavigationStack {
                ScrollView {
                    LazyVStack(spacing: mode == .iPhonePortrait ? AppSpacing.medium : AppSpacing.large) {
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
                        statisticsContent(for: mode)
                        if viewModel.selectedPeriod == .month && mode == .iPhonePortrait {
                            MonthlyCashFlowCalendar(
                                month: viewModel.selectedDate,
                                items: viewModel.dailyCashFlow
                            )
                        }
                    }
                    .padding(.horizontal, mode == .iPhonePortrait ? AppSpacing.medium : AppSpacing.xLarge)
                    .padding(.top, AppSpacing.xSmall)
                    .padding(.bottom, AppSpacing.xxLarge)
                    .frame(maxWidth: mode == .iPhonePortrait ? .infinity : 1240)
                    .frame(maxWidth: .infinity)
                }
                .appScreenBackground()
                .navigationTitle("Thống kê")
                .navigationBarTitleDisplayMode(.inline)
                .task { await viewModel.load() }
                .refreshable { await viewModel.load() }
                .appLoadingOverlay(viewModel.isLoading, message: "Đang tải thống kê…")
            }
            .appIPadTypography(isEnabled: mode != .iPhonePortrait)
        }
    }

    @ViewBuilder
    private func statisticsContent(for mode: LayoutMode) -> some View {
        if !viewModel.hasChartData {
            EmptyStateView(
                icon: "chart.bar",
                title: "Chưa có dữ liệu",
                message: "Biểu đồ sẽ xuất hiện khi bạn có \(viewModel.selectedType.title.lowercased()) trong khoảng thời gian đã chọn."
            )
            .frame(minHeight: 280)
            .appCard(padding: 0)
        } else if mode == .iPadLandscape {
            HStack(alignment: .top, spacing: AppSpacing.large) {
                VStack(spacing: AppSpacing.large) {
                    DailySpendingChart(
                        items: viewModel.dailySpending,
                        period: viewModel.selectedPeriod,
                        transactionType: viewModel.selectedType
                    )
                    if viewModel.selectedPeriod == .month {
                        MonthlyCashFlowCalendar(
                            month: viewModel.selectedDate,
                            items: viewModel.dailyCashFlow
                        )
                    }
                }
                CategorySpendingChart(
                    items: viewModel.categorySpending,
                    transactionType: viewModel.selectedType
                )
            }
        } else if mode == .iPadPortrait {
            DailySpendingChart(
                items: viewModel.dailySpending,
                period: viewModel.selectedPeriod,
                transactionType: viewModel.selectedType
            )
            if viewModel.selectedPeriod == .month {
                MonthlyCashFlowCalendar(
                    month: viewModel.selectedDate,
                    items: viewModel.dailyCashFlow
                )
            }
            CategorySpendingChart(
                items: viewModel.categorySpending,
                transactionType: viewModel.selectedType
            )
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

    private func layoutMode(for size: CGSize) -> LayoutMode {
        if size.width >= 900 && size.width > size.height {
            return .iPadLandscape
        }
        if size.width >= 600 {
            return .iPadPortrait
        }
        return .iPhonePortrait
    }
}
