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
    var passwordConfirmation = ""
    var isRestoring = true
    var isSubmitting = false
    var errorMessage: String?
    var didAttemptValidation = false

    private let auth: AuthUseCases

    init(auth: AuthUseCases) {
        self.auth = auth
    }

    var isAuthenticated: Bool { user != nil }

    var emailValidationMessage: String? {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard didAttemptValidation || !value.isEmpty else { return nil }
        guard !value.isEmpty else { return "Vui lòng nhập email." }
        guard value.count <= 255,
              value.range(
                  of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
                  options: .regularExpression
              ) != nil else {
            return "Email không hợp lệ."
        }
        return nil
    }

    var passwordValidationMessage: String? {
        guard didAttemptValidation || !password.isEmpty else { return nil }
        guard !password.isEmpty else { return "Vui lòng nhập mật khẩu." }
        guard (8...72).contains(password.count) else {
            return "Mật khẩu phải có từ 8 đến 72 ký tự."
        }
        return nil
    }

    var passwordConfirmationValidationMessage: String? {
        guard mode == .register else { return nil }
        guard didAttemptValidation || !passwordConfirmation.isEmpty else { return nil }
        guard !passwordConfirmation.isEmpty else { return "Vui lòng nhập lại mật khẩu." }
        guard passwordConfirmation == password else {
            return "Mật khẩu nhập lại không khớp."
        }
        return nil
    }

    var canSubmit: Bool {
        emailValidationMessage == nil
            && passwordValidationMessage == nil
            && passwordConfirmationValidationMessage == nil
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && (mode == .login || !passwordConfirmation.isEmpty)
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
        didAttemptValidation = true
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
            passwordConfirmation = ""
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    func switchMode() {
        mode = mode == .login ? .register : .login
        password = ""
        passwordConfirmation = ""
        errorMessage = nil
        didAttemptValidation = false
    }

    func logout() async {
        isSubmitting = true
        defer {
            isSubmitting = false
            user = nil
            email = ""
            password = ""
            passwordConfirmation = ""
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
        passwordConfirmation = ""
        mode = .login
        errorMessage = DomainError.sessionExpired.userMessage
    }
}
