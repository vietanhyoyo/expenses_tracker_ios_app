import SwiftUI

struct AuthView: View {
    private enum LayoutMode {
        case iPhonePortrait
        case iPadPortrait
        case iPadLandscape
    }

    @Bindable var viewModel: SessionViewModel
    @State private var isPasswordVisible = false
    @State private var isPasswordConfirmationVisible = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                authBackground

                switch layoutMode(for: proxy.size) {
                case .iPhonePortrait:
                    compactLayout(proxy: proxy)
                case .iPadPortrait:
                    iPadPortraitLayout(proxy: proxy)
                case .iPadLandscape:
                    wideLayout(proxy: proxy)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .id("\(proxy.size.width)x\(proxy.size.height)")
        }
        .ignoresSafeArea()
        .background(Color.white.ignoresSafeArea())
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private func compactLayout(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            header(topInset: proxy.safeAreaInsets.top)

            formCard(
                bottomInset: proxy.safeAreaInsets.bottom,
                contentMaxWidth: proxy.size.width - 24,
                contentTopPadding: 27,
                horizontalPadding: 12
            )
            .environment(\.colorScheme, .light)
            .frame(
                width: proxy.size.width,
                height: max(min(max(proxy.size.height * 0.64, 500), 620) - 30, 470),
                alignment: .top
            )
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
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
    }

    private func iPadPortraitLayout(proxy: GeometryProxy) -> some View {
        let bottomInset = proxy.safeAreaInsets.bottom
        let baseCardHeight = min(max(proxy.size.height * 0.46, 500), 680)
        let cardHeight = baseCardHeight + bottomInset
        let brandHeight = max(proxy.size.height - baseCardHeight, 0)

        return ZStack(alignment: .bottom) {
            VStack(spacing: 14) {
                Image("MainLogoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .accessibilityHidden(true)

                Text("App quản lý chi tiêu")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: proxy.size.width, height: brandHeight)
            .position(x: proxy.size.width / 2, y: brandHeight / 2)

            formCard(
                bottomInset: proxy.safeAreaInsets.bottom,
                contentMaxWidth: 400,
                contentTopPadding: 38
            )
            .environment(\.colorScheme, .light)
            .frame(width: proxy.size.width, height: cardHeight)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 28
                )
            )
        }
        .frame(width: proxy.size.width, height: proxy.size.height + bottomInset)
    }

    private func wideLayout(proxy: GeometryProxy) -> some View {
        let leftInset = max(proxy.safeAreaInsets.leading, 24)
        let rightInset = max(proxy.safeAreaInsets.trailing, 40)
        let cardWidth = min(max(proxy.size.width * 0.33, 380), 430)
        let cardHeight = min(max(proxy.size.height - 64, 560), 720)
        let cardX = proxy.size.width - rightInset - (cardWidth / 2)
        let brandWidth = max(proxy.size.width - leftInset - rightInset - cardWidth, 0)

        return ZStack(alignment: .topLeading) {
            Color.clear
                .frame(width: proxy.size.width, height: proxy.size.height)

            VStack(spacing: 16) {
                Image("MainLogoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .accessibilityHidden(true)

                Text("App quản lý chi tiêu")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: brandWidth, height: proxy.size.height)
            .position(
                x: leftInset + (brandWidth / 2),
                y: proxy.size.height / 2
            )

            formCard(
                bottomInset: 0,
                contentMaxWidth: nil,
                contentTopPadding: 154
            )
            .environment(\.colorScheme, .light)
            .frame(width: cardWidth, height: cardHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .position(
                x: cardX,
                y: proxy.size.height / 2
            )
        }
    }

    private func layoutMode(for size: CGSize) -> LayoutMode {
        switch size {
        case let size where size.width >= 900 && size.width > size.height:
            return .iPadLandscape
        case let size where size.width >= 700 && size.height > size.width:
            return .iPadPortrait
        default:
            return .iPhonePortrait
        }
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
                .frame(height: topInset + 96)

            Image("MainLogoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 144, height: 144)
                .accessibilityHidden(true)

            Text("App quản lý chi tiêu")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func formCard(
        bottomInset: CGFloat,
        contentMaxWidth: CGFloat?,
        contentTopPadding: CGFloat,
        horizontalPadding: CGFloat = 22
    ) -> some View {
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
                        .frame(height: 52)
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
                    .frame(height: 52)
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
                        .frame(height: 52)
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
                    .frame(height: 52)
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
            .padding(.horizontal, horizontalPadding)
            .padding(.top, contentTopPadding)
            .padding(.bottom, bottomInset + 25)
            .frame(width: contentMaxWidth ?? nil, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
