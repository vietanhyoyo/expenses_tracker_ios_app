extension DomainError {
    var userMessage: String {
        switch self {
        case .invalidAmount: "Số tiền phải lớn hơn 0."
        case .invalidName: "Tên không được để trống."
        case .invalidTransactionType: "Danh mục không phù hợp với loại giao dịch."
        case .accountNotFound: "Không tìm thấy tài khoản."
        case .categoryNotFound: "Không tìm thấy danh mục."
        case .transactionNotFound: "Không tìm thấy giao dịch."
        case .budgetNotFound: "Không tìm thấy ngân sách."
        case .duplicateBudget: "Danh mục này đã có ngân sách trong tháng."
        case .itemInUse: "Không thể xoá vì mục này đang được sử dụng."
        case .persistenceError: "Không thể lưu dữ liệu. Vui lòng thử lại."
        }
    }
}

extension Error {
    var userMessage: String {
        (self as? DomainError)?.userMessage
            ?? "Đã có lỗi xảy ra. Vui lòng thử lại."
    }
}
