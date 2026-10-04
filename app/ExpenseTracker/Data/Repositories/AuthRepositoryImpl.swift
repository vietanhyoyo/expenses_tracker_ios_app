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
            let user: CurrentUserResponse = try await api.get(APIEndpoints.Users.me)
            return try map(user)
        } catch {
            throw ErrorMapper.map(error)
        }
    }

    func login(email: String, password: String) async throws -> AuthUser {
        try await authenticate(path: APIEndpoints.Auth.login, email: email, password: password)
    }

    func register(email: String, password: String) async throws -> AuthUser {
        try await authenticate(path: APIEndpoints.Auth.register, email: email, password: password)
    }

    func logout() async throws {
        do {
            guard let tokens = try tokenStore.load() else { return }
            defer { try? tokenStore.clear() }
            let _: APIEmptyResponse? = try await api.post(
                APIEndpoints.Auth.logout,
                body: RefreshTokenRequest(refreshToken: tokens.refreshToken)
            )
        } catch {
            try? tokenStore.clear()
            throw ErrorMapper.map(error)
        }
    }

    private func authenticate(
        path: String,
        email: String,
        password: String
    ) async throws -> AuthUser {
        do {
            let result: AuthResultResponse = try await api.post(
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
            throw ErrorMapper.map(error)
        }
    }

    private func map(_ response: AuthUserResponse) throws -> AuthUser {
        guard let createdAt = DateParser.date(from: response.createdAt) else {
            throw DomainError.remoteError("Ngày tạo tài khoản không hợp lệ.")
        }
        return AuthUser(id: response.id, email: response.email, createdAt: createdAt)
    }

    private func map(_ response: CurrentUserResponse) throws -> AuthUser {
        guard let createdAt = DateParser.date(from: response.createdAt) else {
            throw DomainError.remoteError("Ngày tạo tài khoản không hợp lệ.")
        }
        return AuthUser(id: response.id, email: response.email, createdAt: createdAt)
    }
}
