import Foundation

struct AuthUser: Equatable, Sendable {
    let id: Int
    let email: String
    let createdAt: Date
}
