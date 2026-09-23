import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: SessionViewModel
    @State private var isPasswordVisible = false
    @State private var isPasswordConfirmationVisible = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                authBackground
                header(topInset: proxy.safeAreaInsets.top)
                formCard(bottomInset: proxy.safeAreaInsets.bottom)
                    .environment(\.colorScheme, .light)
                    .frame(
                        width: proxy.size.width,
                        height: max(min(max(proxy.size.height * 0.64, 500), 620) - 30, 470)
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .background(Color.white.ignoresSafeArea())
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private var authBackground: some View {
        ZStack {
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
    }

    private func header(topInset: CGFloat) -> some View {
        VStack(spacing: 9) {
            Spacer()
                .frame(height: topInset + 38)

            Image("MainLogoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)

            Text("App quản lý chi tiêu")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func formCard(bottomInset: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 7) {
                    Text(viewModel.mode == .login ? "ĐĂNG NHẬP" : "ĐĂNG KÝ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(viewModel.mode == .login
                        ? "Dùng tài khoản của bạn để đồng bộ khoản chi"
                        : "Tạo tài khoản để bắt đầu quản lý khoản chi")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.45, green: 0.48, blue: 0.56))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 31)

                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel("Email")
                    TextField("Nhập email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .padding(.horizontal, 15)
                        .frame(height: 46)
                        .background(Color(hex: "F1F1F1"), in: RoundedRectangle(cornerRadius: 14))

                    validationMessage(viewModel.emailValidationMessage)

                    fieldLabel("Mật khẩu")
                        .padding(.top, 7)
                    HStack(spacing: 8) {
                        Group {
                            if isPasswordVisible {
                                TextField("Nhập mật khẩu", text: $viewModel.password)
                            } else {
                                SecureField("Nhập mật khẩu", text: $viewModel.password)
                            }
                        }
                        .textContentType(viewModel.mode == .login ? .password : .newPassword)
                        .submitLabel(.go)
                        .onSubmit(submit)

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color(red: 0.35, green: 0.36, blue: 0.40))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPasswordVisible ? "Ẩn mật khẩu" : "Hiện mật khẩu")
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 46)
                    .background(Color(hex: "F1F1F1"), in: RoundedRectangle(cornerRadius: 14))

                    validationMessage(viewModel.passwordValidationMessage)

                    if viewModel.mode == .register {
                        fieldLabel("Nhập lại mật khẩu")
                            .padding(.top, 7)
                        HStack(spacing: 8) {
                            Group {
                                if isPasswordConfirmationVisible {
                                    TextField("Nhập lại mật khẩu", text: $viewModel.passwordConfirmation)
                                } else {
                                    SecureField("Nhập lại mật khẩu", text: $viewModel.passwordConfirmation)
                                }
                            }
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .onSubmit(submit)

                            Button {
                                isPasswordConfirmationVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordConfirmationVisible ? "eye.slash" : "eye")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color(red: 0.35, green: 0.36, blue: 0.40))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                isPasswordConfirmationVisible
                                    ? "Ẩn mật khẩu nhập lại"
                                    : "Hiện mật khẩu nhập lại"
                            )
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 46)
                        .background(Color(hex: "F1F1F1"), in: RoundedRectangle(cornerRadius: 14))

                        validationMessage(viewModel.passwordConfirmationValidationMessage)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.coral)
                        .padding(.top, 11)
                }

                Button(action: submit) {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(viewModel.mode == .login ? "ĐĂNG NHẬP" : "ĐĂNG KÝ")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                }
                .background(AppTheme.primary, in: Capsule())
                .buttonStyle(.plain)
                .disabled(viewModel.isSubmitting)
                .padding(.top, 27)

                Button(viewModel.mode == .login
                    ? "Chưa có tài khoản? Đăng ký"
                    : "Đã có tài khoản? Đăng nhập") {
                    viewModel.switchMode()
                    isPasswordVisible = false
                    isPasswordConfirmationVisible = false
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
                .disabled(viewModel.isSubmitting)
                .padding(.top, 29)
            }
            .padding(.horizontal, 22)
            .padding(.top, 27)
            .padding(.bottom, bottomInset + 25)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 34,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 34
            )
        )
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.43, green: 0.46, blue: 0.54))
    }

    @ViewBuilder
    private func validationMessage(_ message: String?) -> some View {
        if let message {
            Text(message)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.coral)
        }
    }

    private func submit() {
        Task { _ = await viewModel.submit() }
    }
}
