import Foundation
import Observation

@MainActor
@Observable
final class TransactionFormViewModel {
    let id: UUID
    let isEditing: Bool
    var type: TransactionType
    var amountText = ""
    var date: Date
    var note = ""
    var categoryID: UUID?
    var accountID: UUID?
    var categories: [ExpenseCategory] = []
    var accounts: [Account] = []
    var isSaving = false
    var isShowingDeleteConfirmation = false
    var errorMessage: String?
    private(set) var successMessage = ""

    private var hasPendingDeletion = false

    private let transactionUseCases: TransactionUseCases
    private let categoryUseCases: CategoryUseCases
    private let accountUseCases: AccountUseCases

    init(
        existing: ExpenseTransaction?,
        transactionUseCases: TransactionUseCases,
        categoryUseCases: CategoryUseCases,
        accountUseCases: AccountUseCases
    ) {
        id = existing?.id ?? UUID()
        isEditing = existing != nil
        type = existing?.type ?? .expense
        date = existing?.date ?? Date()
        note = existing?.note ?? ""
        categoryID = existing?.categoryID
        accountID = existing?.accountID
        if let amount = existing?.amount {
            amountText = AppFormatters.vietnameseMoneyInput(from: amount)
        }
        self.transactionUseCases = transactionUseCases
        self.categoryUseCases = categoryUseCases
        self.accountUseCases = accountUseCases
    }

    var availableCategories: [ExpenseCategory] {
        categories.filter { $0.type == type }
    }

    var canSave: Bool {
        (parsedAmount ?? 0) > 0
            && categoryID != nil
            && accountID != nil
            && !isSaving
    }

    func load() async {
        do {
            categories = try await categoryUseCases.getAll()
            accounts = try await accountUseCases.getAll()
            selectValidDefaults()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func typeChanged() {
        categoryID = availableCategories.first?.id
    }

    func requestDeletion() {
        guard isEditing, !isSaving else { return }
        hasPendingDeletion = true
        isShowingDeleteConfirmation = true
    }

    func cancelDeletion() {
        hasPendingDeletion = false
        isShowingDeleteConfirmation = false
    }

    func confirmDeletion() async -> Bool {
        guard hasPendingDeletion else { return false }
        cancelDeletion()
        return await delete()
    }

    func save() async -> Bool {
        guard let transaction = makeTransaction() else {
            errorMessage = DomainError.invalidAmount.userMessage
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await transactionUseCases.save(transaction, isEditing: isEditing)
            if isEditing {
                successMessage = "Đã cập nhật giao dịch thành công"
            } else {
                successMessage = type == .income
                    ? "Đã thêm khoản thu thành công"
                    : "Đã thêm khoản chi thành công"
            }
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    private func delete() async -> Bool {
        guard isEditing else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await transactionUseCases.delete(id: id)
            successMessage = "Đã xoá giao dịch thành công"
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    private var parsedAmount: Decimal? {
        AppFormatters.decimal(from: amountText)
    }

    private func selectValidDefaults() {
        if !availableCategories.contains(where: { $0.id == categoryID }) {
            categoryID = availableCategories.first?.id
        }
        if !accounts.contains(where: { $0.id == accountID }) {
            accountID = accounts.first?.id
        }
    }

    private func makeTransaction() -> ExpenseTransaction? {
        guard let amount = parsedAmount, let categoryID, let accountID else {
            return nil
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return ExpenseTransaction(
            id: id,
            amount: amount,
            type: type,
            date: date,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            categoryID: categoryID,
            accountID: accountID
        )
    }
}
