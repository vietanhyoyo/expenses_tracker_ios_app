import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: SessionViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.teal.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xLarge) {
                    header
                    formCard
                }
                .padding(.horizontal, AppSpacing.large)
                .padding(.vertical, 64)
            }
        }
        .tint(AppTheme.teal)
    }

    private var header: some View {
        VStack(spacing: AppSpacing.medium) {
            AppIconBadge(
                icon: "wallet.bifold.fill",
                color: AppTheme.teal,
                size: 82
            )
            VStack(spacing: AppSpacing.xxSmall) {
                Text("Sổ Thu Chi")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Quản lý chi tiêu an toàn trên mọi phiên đăng nhập")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: AppSpacing.medium) {
            VStack(spacing: AppSpacing.xxxSmall) {
                Text(viewModel.mode == .login ? "Đăng nhập" : "Tạo tài khoản")
                    .font(AppTypography.sectionTitle)
                Text(viewModel.mode == .login
                    ? "Dùng tài khoản của bạn để đồng bộ khoản chi."
                    : "Đăng ký để bắt đầu lưu khoản chi trên máy chủ.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppSpacing.small) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .padding(AppSpacing.medium)
                    .background(AppTheme.background, in: RoundedRectangle(cornerRadius: AppRadius.medium))

                SecureField("Mật khẩu (8–72 ký tự)", text: $viewModel.password)
                    .textContentType(viewModel.mode == .login ? .password : .newPassword)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .padding(AppSpacing.medium)
                    .background(AppTheme.background, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Button(action: submit) {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(viewModel.mode == .login ? "Đăng nhập" : "Đăng ký")
                            .font(AppTypography.bodyEmphasis)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: AppRadius.medium))
            .disabled(!viewModel.canSubmit)

            Button(viewModel.mode == .login
                ? "Chưa có tài khoản? Đăng ký"
                : "Đã có tài khoản? Đăng nhập") {
                viewModel.switchMode()
            }
            .font(AppTypography.caption)
            .disabled(viewModel.isSubmitting)
        }
        .padding(AppSpacing.large)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
        .shadow(color: AppTheme.navy.opacity(0.08), radius: 20, y: 8)
    }

    private func submit() {
        Task { _ = await viewModel.submit() }
    }
}
