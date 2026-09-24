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
        case .invalidEmail: "Email không hợp lệ."
        case .invalidPassword: "Mật khẩu phải có từ 8 đến 72 ký tự."
        case .invalidCredentials: "Email hoặc mật khẩu không đúng."
        case .emailAlreadyExists: "Email này đã được đăng ký."
        case .authenticationRequired: "Vui lòng đăng nhập để tiếp tục."
        case .sessionExpired: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        case .categoryNotEditable: "Danh mục mặc định của hệ thống không thể chỉnh sửa."
        case .duplicateCategory: "Tên danh mục đã tồn tại."
        case .invalidCategoryReplacement: "Vui lòng chọn danh mục thay thế cùng loại."
        case .duplicateAccount: "Tên tài khoản đã tồn tại."
        case .networkUnavailable: "Không thể kết nối máy chủ. Vui lòng kiểm tra lại kết nối."
        case let .remoteError(message): message
        }
    }
}

extension Error {
    var userMessage: String {
        (self as? DomainError)?.userMessage
            ?? "Đã có lỗi xảy ra. Vui lòng thử lại."
    }
}
