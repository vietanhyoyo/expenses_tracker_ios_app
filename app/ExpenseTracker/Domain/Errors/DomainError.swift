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
    case invalidEmail
    case invalidPassword
    case invalidCredentials
    case emailAlreadyExists
    case authenticationRequired
    case sessionExpired
    case categoryNotEditable
    case duplicateCategory
    case invalidCategoryReplacement
    case duplicateAccount
    case networkUnavailable
    case remoteError(String)
}
