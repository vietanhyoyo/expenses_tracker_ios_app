import Foundation

@MainActor
struct AuthUseCases {
    let repository: any AuthRepository

    func restoreSession() async throws -> AuthUser? {
        try await repository.restoreSession()
    }

    func login(email: String, password: String) async throws -> AuthUser {
        try validate(email: email, password: password)
        return try await repository.login(
            email: normalizedEmail(email),
            password: password
        )
    }

    func register(email: String, password: String) async throws -> AuthUser {
        try validate(email: email, password: password)
        return try await repository.register(
            email: normalizedEmail(email),
            password: password
        )
    }

    func logout() async throws {
        try await repository.logout()
    }

    private func validate(email: String, password: String) throws {
        let normalized = normalizedEmail(email)
        guard normalized.count <= 255,
              normalized.range(
                of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
                options: .regularExpression
              ) != nil else {
            throw DomainError.invalidEmail
        }
        guard (8...72).contains(password.count) else {
            throw DomainError.invalidPassword
        }
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
