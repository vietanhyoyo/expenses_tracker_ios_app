import Foundation

@MainActor
protocol AuthRepository {
    func restoreSession() async throws -> AuthUser?
    func login(email: String, password: String) async throws -> AuthUser
    func register(email: String, password: String) async throws -> AuthUser
    func logout() async throws
}
