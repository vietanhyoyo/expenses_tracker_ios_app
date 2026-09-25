import Foundation
import Observation

@MainActor
@Observable
final class CategoryFormViewModel {
    let isEditing: Bool
    var name: String
    var icon: String
    var type: TransactionType
    var colorHex: String
    var isSaving = false
    var errorMessage: String?

    private let id: UUID
    private let categoryUseCases: CategoryUseCases

    init(category: ExpenseCategory?, categoryUseCases: CategoryUseCases) {
        id = category?.id ?? UUID()
        isEditing = category != nil
        name = category?.name ?? ""
        icon = category?.icon ?? "star.fill"
        type = category?.type ?? .expense
        colorHex = category?.colorHex ?? ExpenseCategory.defaultColorHex(for: .expense)
        self.categoryUseCases = categoryUseCases
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    /// A new category switches to the default color of the selected type;
    /// an existing category keeps its color.
    func typeChanged() {
        guard !isEditing else { return }
        colorHex = ExpenseCategory.defaultColorHex(for: type)
    }

    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let category = ExpenseCategory(
            id: id,
            name: name,
            icon: icon,
            type: type,
            colorHex: colorHex
        )
        do {
            try await categoryUseCases.save(category, isEditing: isEditing)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }
}
