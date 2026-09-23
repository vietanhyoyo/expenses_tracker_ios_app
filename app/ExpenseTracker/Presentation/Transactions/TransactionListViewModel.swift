import Foundation
import Observation

@MainActor
@Observable
final class TransactionListViewModel {
    var isLoading = false
    var errorMessage: String?
    var transactions: [ExpenseTransaction] = []
    var categories: [UUID: ExpenseCategory] = [:]
    var accounts: [UUID: Account] = [:]
    var query = ""
    var selectedType: TransactionType?
    var selectedCategoryID: UUID?
    var selectedAccountID: UUID?
    var isDateRangeEnabled = false
    var fromDate: Date?
    var toDate: Date?
    var sort: TransactionSort = .newest

    private let useCases: TransactionUseCases
    private let categoryUseCases: CategoryUseCases
    private let accountUseCases: AccountUseCases

    init(
        transactions: TransactionUseCases,
        categories: CategoryUseCases,
        accounts: AccountUseCases
    ) {
        useCases = transactions
        categoryUseCases = categories
        accountUseCases = accounts
    }

    var filtered: [ExpenseTransaction] {
        let matchingTransactions = transactions.filter { transaction in
            matchesQuery(transaction)
                && (selectedType == nil || transaction.type == selectedType)
                && (selectedCategoryID == nil || transaction.categoryID == selectedCategoryID)
                && (selectedAccountID == nil || transaction.accountID == selectedAccountID)
                && matchesDateRange(transaction)
        }

        switch sort {
        case .newest:
            return matchingTransactions.sorted { $0.date > $1.date }
        case .oldest:
            return matchingTransactions.sorted { $0.date < $1.date }
        case .highest:
            return matchingTransactions.sorted { $0.amount > $1.amount }
        case .lowest:
            return matchingTransactions.sorted { $0.amount < $1.amount }
        }
    }

    /// Filtered transactions grouped by day. Days follow the date direction of
    /// `sort`; transactions inside a day keep the order produced by `filtered`.
    var daySections: [TransactionDayGroup] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }
            .map { TransactionDayGroup(day: $0.key, transactions: $0.value) }

        return sort == .oldest
            ? groups.sorted { $0.day < $1.day }
            : groups.sorted { $0.day > $1.day }
    }

    var hasFilters: Bool {
        selectedType != nil
            || selectedCategoryID != nil
            || selectedAccountID != nil
            || isDateRangeEnabled
            || sort != .newest
    }

    var isDateRangeValid: Bool {
        guard isDateRangeEnabled else { return true }
        guard let fromDate, let toDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: fromDate) <= calendar.startOfDay(for: toDate)
    }

    var hasSearchOrFilters: Bool {
        !query.isEmpty || hasFilters
    }

    /// True only for the first load, so refreshes keep the current list visible.
    var isInitialLoading: Bool {
        isLoading && transactions.isEmpty
    }

    var sortedCategories: [ExpenseCategory] {
        categories.values.sorted { $0.name < $1.name }
    }

    var sortedAccounts: [Account] {
        accounts.values.sorted { $0.name < $1.name }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            transactions = try await useCases.getAll(
                from: isDateRangeEnabled ? fromDate : nil,
                to: isDateRangeEnabled ? toDate : nil,
                type: selectedType,
                categoryID: selectedCategoryID
            )
            categories = try await categoryUseCases.getAll().keyedByID()
            accounts = try await accountUseCases.getAll().keyedByID()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(_ transaction: ExpenseTransaction) async {
        do {
            try await useCases.delete(id: transaction.id)
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func clearFilters() {
        selectedType = nil
        selectedCategoryID = nil
        selectedAccountID = nil
        isDateRangeEnabled = false
        fromDate = nil
        toDate = nil
        sort = .newest
    }

    func setDateRangeEnabled(_ enabled: Bool) {
        isDateRangeEnabled = enabled
        guard enabled else {
            fromDate = nil
            toDate = nil
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        fromDate = fromDate ?? Calendar.current.date(byAdding: .month, value: -1, to: today)
        toDate = toDate ?? today
    }

    private func matchesQuery(_ transaction: ExpenseTransaction) -> Bool {
        guard !query.isEmpty else { return true }

        let noteMatches = transaction.note?.localizedCaseInsensitiveContains(query) == true
        let categoryMatches = categories[transaction.categoryID]?
            .name
            .localizedCaseInsensitiveContains(query) == true
        return noteMatches || categoryMatches
    }

    private func matchesDateRange(_ transaction: ExpenseTransaction) -> Bool {
        guard isDateRangeEnabled else { return true }
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: transaction.date)
        if let fromDate, day < calendar.startOfDay(for: fromDate) { return false }
        if let toDate,
           let dayAfterToDate = calendar.date(
               byAdding: .day,
               value: 1,
               to: calendar.startOfDay(for: toDate)
           ),
           day >= dayAfterToDate {
            return false
        }
        return true
    }
}
