import Foundation
import Observation

@MainActor
@Observable
final class SessionViewModel {
    enum Mode {
        case login
        case register
    }

    var user: AuthUser?
    var mode: Mode = .login
    var email = ""
    var password = ""
    var isRestoring = true
    var isSubmitting = false
    var errorMessage: String?

    private let auth: AuthUseCases

    init(auth: AuthUseCases) {
        self.auth = auth
    }

    var isAuthenticated: Bool { user != nil }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !isSubmitting
    }

    func restore() async {
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }

        do {
            user = try await auth.restoreSession()
        } catch {
            user = nil
            errorMessage = error.userMessage
        }
    }

    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            switch mode {
            case .login:
                user = try await auth.login(email: email, password: password)
            case .register:
                user = try await auth.register(email: email, password: password)
            }
            password = ""
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    func switchMode() {
        mode = mode == .login ? .register : .login
        password = ""
        errorMessage = nil
    }

    func logout() async {
        isSubmitting = true
        defer {
            isSubmitting = false
            user = nil
            email = ""
            password = ""
            mode = .login
        }
        do {
            try await auth.logout()
            errorMessage = nil
        } catch {
            errorMessage = error.userMessage
        }
    }

    func sessionDidExpire() {
        user = nil
        password = ""
        mode = .login
        errorMessage = DomainError.sessionExpired.userMessage
    }
}
