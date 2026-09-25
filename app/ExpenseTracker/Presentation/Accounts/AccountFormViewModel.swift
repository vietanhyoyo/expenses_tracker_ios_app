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
    private let accountUseCases: AccountUseCases

    init(account: Account?, accountUseCases: AccountUseCases) {
        id = account?.id ?? UUID()
        isEditing = account != nil
        name = account?.name ?? ""
        initialBalanceText = account.map {
            AppFormatters.vietnameseMoneyInput(from: $0.initialBalance)
        } ?? ""
        self.accountUseCases = accountUseCases
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
            try await accountUseCases.save(account, isEditing: isEditing)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
