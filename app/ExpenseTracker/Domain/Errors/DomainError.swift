import Foundation

enum DomainError: Error, Equatable {
    case invalidAmount
    case invalidName
    case invalidTransactionType
    case accountNotFound
    case categoryNotFound
    case transactionNotFound
    case budgetNotFound
    case duplicateBudget
    case itemInUse
    case persistenceError
}
