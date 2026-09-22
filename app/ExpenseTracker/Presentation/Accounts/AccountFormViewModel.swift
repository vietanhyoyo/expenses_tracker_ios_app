import Foundation
import Observation

@MainActor
@Observable
final class AccountFormViewModel {
    let isEditing: Bool
    var name: String
    var initialBalanceText: String
    var isSaving = false
    var errorMessage: String?

    private let id: UUID
    private let useCases: AccountUseCases

    init(account: Account?, useCases: AccountUseCases) {
        id = account?.id ?? UUID()
        isEditing = account != nil
        name = account?.name ?? ""
        initialBalanceText = account.map {
            AppFormatters.vietnameseMoneyInput(from: $0.initialBalance)
        } ?? ""
        self.useCases = useCases
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let account = Account(
            id: id,
            name: name,
            initialBalance: AppFormatters.decimal(from: initialBalanceText) ?? 0
        )
        do {
            try await useCases.save(account, isEditing: isEditing)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
