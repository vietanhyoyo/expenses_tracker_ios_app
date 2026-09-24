import Foundation

enum ErrorMapper {
    static func map(_ error: Error) -> DomainError {
        if let domainError = error as? DomainError { return domainError }
        if error is URLError { return .networkUnavailable }

        guard let apiError = error as? APIClientError else {
            return .remoteError("Đã có lỗi xảy ra. Vui lòng thử lại.")
        }

        switch apiError {
        case .invalidResponse:
            return .remoteError("Dữ liệu trả về từ máy chủ không hợp lệ.")
        case let .transport(underlying):
            return underlying is URLError
                ? .networkUnavailable
                : .remoteError("Không thể kết nối máy chủ.")
        case let .http(_, code, message):
            switch code {
            case "INVALID_CREDENTIALS": return .invalidCredentials
            case "EMAIL_ALREADY_EXISTS": return .emailAlreadyExists
            case "ACCESS_TOKEN_INVALID", "ACCESS_TOKEN_EXPIRED", "UNAUTHORIZED",
                 "REFRESH_TOKEN_INVALID", "REFRESH_TOKEN_EXPIRED", "REFRESH_TOKEN_REVOKED":
                return .sessionExpired
            case "CATEGORY_NOT_EDITABLE": return .categoryNotEditable
            case "CATEGORY_ALREADY_EXISTS": return .duplicateCategory
            case "CATEGORY_REPLACEMENT_INVALID": return .invalidCategoryReplacement
            case "CATEGORY_IN_USE": return .itemInUse
            case "CATEGORY_NOT_FOUND": return .categoryNotFound
            case "EXPENSE_NOT_FOUND", "TRANSACTION_NOT_FOUND": return .transactionNotFound
            case "ACCOUNT_NOT_FOUND": return .accountNotFound
            case "ACCOUNT_ALREADY_EXISTS": return .duplicateAccount
            case "ACCOUNT_NOT_EDITABLE": return .itemInUse
            case "BUDGET_NOT_FOUND": return .budgetNotFound
            case "BUDGET_ALREADY_EXISTS": return .duplicateBudget
            default: return .remoteError(message)
            }
        }
    }
}
