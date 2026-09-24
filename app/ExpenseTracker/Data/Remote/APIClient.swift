import Foundation

enum APIClientError: Error {
    case invalidResponse
    case http(status: Int, code: String?, message: String)
    case transport(Error)
}

@MainActor
final class APIClient {
    var onSessionInvalidated: (() -> Void)?

    private let baseURL: URL
    private let tokenStore: any TokenStore
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        baseURL: URL,
        tokenStore: any TokenStore,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = session
    }

    func get<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        authorized: Bool = true
    ) async throws -> Response {
        try await send(
            path,
            method: "GET",
            queryItems: queryItems,
            body: nil,
            authorized: authorized,
            canRefresh: true
        )
    }

    func post<Response: Decodable, Body: Encodable>(
        _ path: String,
        body: Body,
        authorized: Bool = true
    ) async throws -> Response {
        try await send(
            path,
            method: "POST",
            body: try encoder.encode(body),
            authorized: authorized,
            canRefresh: true
        )
    }

    func patch<Response: Decodable, Body: Encodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        try await send(
            path,
            method: "PATCH",
            body: try encoder.encode(body),
            authorized: true,
            canRefresh: true
        )
    }

    func delete<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await send(
            path,
            method: "DELETE",
            queryItems: queryItems,
            body: nil,
            authorized: true,
            canRefresh: true
        )
    }

    private func send<Response: Decodable>(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data?,
        authorized: Bool,
        canRefresh: Bool
    ) async throws -> Response {
        var request = try makeRequest(
            path: path,
            method: method,
            queryItems: queryItems,
            body: body
        )

        if authorized {
            guard let tokens = try tokenStore.load() else {
                throw DomainError.authenticationRequired
            }
            request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            return try await perform(request)
        } catch let error as APIClientError {
            guard authorized,
                  canRefresh,
                  case let .http(_, code, _) = error,
                  code == "ACCESS_TOKEN_EXPIRED" else {
                if authorized, case let .http(status, code, _) = error,
                   status == 401,
                   code != "INVALID_CREDENTIALS" {
                    invalidateSession()
                }
                throw error
            }

            do {
                try await refreshTokens()
                return try await send(
                    path,
                    method: method,
                    queryItems: queryItems,
                    body: body,
                    authorized: true,
                    canRefresh: false
                )
            } catch {
                invalidateSession()
                throw error
            }
        }
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let payload = try? decoder.decode(APIErrorPayload.self, from: data)
            throw APIClientError.http(
                status: http.statusCode,
                code: payload?.errorCode,
                message: payload?.message ?? "Máy chủ trả về lỗi \(http.statusCode)."
            )
        }

        do {
            return try decoder.decode(APIEnvelope<Response>.self, from: data).data
        } catch {
            throw APIClientError.invalidResponse
        }
    }

    private func refreshTokens() async throws {
        guard let current = try tokenStore.load() else {
            throw DomainError.authenticationRequired
        }
        let body = try encoder.encode(RefreshTokenRequest(refreshToken: current.refreshToken))
        let pair: TokenPairDTO = try await send(
            "/auth/refresh",
            method: "POST",
            body: body,
            authorized: false,
            canRefresh: false
        )
        try tokenStore.save(AuthTokens(
            accessToken: pair.accessToken,
            refreshToken: pair.refreshToken
        ))
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: Data?
    ) throws -> URLRequest {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(cleanPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIClientError.invalidResponse
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw APIClientError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func invalidateSession() {
        try? tokenStore.clear()
        onSessionInvalidated?()
    }
}
