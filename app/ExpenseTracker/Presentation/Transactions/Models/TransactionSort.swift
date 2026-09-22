enum TransactionSort: String, CaseIterable, Sendable {
    case newest
    case oldest
    case highest
    case lowest

    var title: String {
        switch self {
        case .newest: "Mới nhất"
        case .oldest: "Cũ nhất"
        case .highest: "Số tiền cao nhất"
        case .lowest: "Số tiền thấp nhất"
        }
    }
}
