import Foundation

@MainActor
final class AuthRepositoryImpl: AuthRepository {
    private let api: APIClient
    private let tokenStore: any TokenStore

    init(api: APIClient, tokenStore: any TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func restoreSession() async throws -> AuthUser? {
        do {
            guard try tokenStore.load() != nil else { return nil }
            let user: CurrentUserDTO = try await api.get("/users/me")
            return try map(user)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    func login(email: String, password: String) async throws -> AuthUser {
        try await authenticate(path: "/auth/login", email: email, password: password)
    }

    func register(email: String, password: String) async throws -> AuthUser {
        try await authenticate(path: "/auth/register", email: email, password: password)
    }

    func logout() async throws {
        do {
            guard let tokens = try tokenStore.load() else { return }
            defer { try? tokenStore.clear() }
            let _: APIEmpty? = try await api.post(
                "/auth/logout",
                body: RefreshTokenRequest(refreshToken: tokens.refreshToken)
            )
        } catch {
            try? tokenStore.clear()
            throw RemoteErrorMapper.map(error)
        }
    }

    private func authenticate(
        path: String,
        email: String,
        password: String
    ) async throws -> AuthUser {
        do {
            let result: AuthResultDTO = try await api.post(
                path,
                body: CredentialsRequest(email: email, password: password),
                authorized: false
            )
            try tokenStore.save(AuthTokens(
                accessToken: result.accessToken,
                refreshToken: result.refreshToken
            ))
            return try map(result.user)
        } catch {
            throw RemoteErrorMapper.map(error)
        }
    }

    private func map(_ dto: AuthUserDTO) throws -> AuthUser {
        guard let createdAt = RemoteDateParser.date(from: dto.createdAt) else {
            throw DomainError.remoteError("Ngày tạo tài khoản không hợp lệ.")
        }
        return AuthUser(id: dto.id, email: dto.email, createdAt: createdAt)
    }

    private func map(_ dto: CurrentUserDTO) throws -> AuthUser {
        guard let createdAt = RemoteDateParser.date(from: dto.createdAt) else {
            throw DomainError.remoteError("Ngày tạo tài khoản không hợp lệ.")
        }
        return AuthUser(id: dto.id, email: dto.email, createdAt: createdAt)
    }
}
