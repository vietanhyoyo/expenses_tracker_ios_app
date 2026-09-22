import SwiftUI

extension TransactionType {
    var title: String {
        switch self {
        case .income: "Thu nhập"
        case .expense: "Chi tiêu"
        }
    }

    var color: Color {
        switch self {
        case .income: AppTheme.teal
        case .expense: AppTheme.coral
        }
    }
}
