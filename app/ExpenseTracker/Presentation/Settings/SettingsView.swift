import SwiftUI

struct SettingsView: View {
    let factory: any ViewModelFactory
    @Bindable var session: SessionViewModel

    var body: some View {
        NavigationStack {
            List {
                managementSection
                accountSection
                privacySection
            }
            .appFormStyle()
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var accountSection: some View {
        Section("Tài khoản đăng nhập") {
            if let user = session.user {
                LabeledContent("Email", value: user.email)
            }
            Button("Đăng xuất", role: .destructive) {
                Task { await session.logout() }
            }
            .disabled(session.isSubmitting)
        }
    }

    private var managementSection: some View {
        Section("Quản lý") {
            NavigationLink {
                AccountsView(factory: factory)
            } label: {
                SettingsRow(title: "Tài khoản", subtitle: "Ví và số dư", icon: "wallet.bifold.fill", color: AppTheme.teal)
            }
            NavigationLink {
                CategoriesView(factory: factory)
            } label: {
                SettingsRow(title: "Danh mục", subtitle: "Nhóm khoản thu chi", icon: "square.grid.2x2.fill", color: AppTheme.violet)
            }
        }
    }

    private var privacySection: some View {
        Section("Chính sách & quyền riêng tư") {
            NavigationLink {
                SettingsLegalDocumentView(document: .privacyPolicy)
            } label: {
                SettingsRow(
                    title: "Chính sách bảo mật",
                    subtitle: "Cách dữ liệu của bạn được bảo vệ",
                    icon: "lock.shield.fill",
                    color: AppTheme.teal
                )
            }

            NavigationLink {
                SettingsLegalDocumentView(document: .privacyRights)
            } label: {
                SettingsRow(
                    title: "Quyền riêng tư",
                    subtitle: "Quản lý và kiểm soát dữ liệu cá nhân",
                    icon: "hand.raised.fill",
                    color: AppTheme.violet
                )
            }
        }
    }
}

private enum SettingsLegalDocument {
    case privacyPolicy
    case privacyRights

    var title: String {
        switch self {
        case .privacyPolicy: "Chính sách bảo mật"
        case .privacyRights: "Quyền riêng tư"
        }
    }

    var introduction: String {
        switch self {
        case .privacyPolicy:
            "Chúng tôi tôn trọng và bảo vệ thông tin cá nhân của bạn khi sử dụng ứng dụng Sổ Thu Chi."
        case .privacyRights:
            "Bạn luôn có quyền biết, kiểm soát và yêu cầu xử lý dữ liệu của mình trong ứng dụng."
        }
    }

    var sections: [(title: String, body: String)] {
        switch self {
        case .privacyPolicy:
            [
                (
                    "Thông tin được sử dụng",
                    "Ứng dụng sử dụng email, mã tài khoản, giao dịch, danh mục và ngân sách để đồng bộ dữ liệu và cung cấp các tính năng quản lý chi tiêu."
                ),
                (
                    "Bảo vệ tài khoản",
                    "Thông tin xác thực phiên đăng nhập được lưu trữ an toàn trên thiết bị. Không chia sẻ mật khẩu hoặc mã xác thực của bạn cho người khác."
                ),
                (
                    "Sử dụng dữ liệu",
                    "Dữ liệu chỉ được sử dụng cho việc đăng nhập, đồng bộ và hiển thị các báo cáo trong ứng dụng; không dùng để hiển thị quảng cáo cá nhân hóa."
                ),
                (
                    "Thay đổi chính sách",
                    "Nếu chính sách thay đổi, nội dung cập nhật sẽ được hiển thị trong mục này để bạn xem trước khi tiếp tục sử dụng ứng dụng."
                )
            ]
        case .privacyRights:
            [
                (
                    "Quyền truy cập",
                    "Bạn có thể xem lại email, giao dịch, danh mục và ngân sách đã lưu trong các mục tương ứng của ứng dụng."
                ),
                (
                    "Quyền chỉnh sửa",
                    "Bạn có thể cập nhật hoặc xóa các giao dịch, danh mục và ngân sách do mình tạo, tùy theo ràng buộc dữ liệu liên quan."
                ),
                (
                    "Quyền đăng xuất",
                    "Bạn có thể đăng xuất bất cứ lúc nào trong phần Tài khoản đăng nhập. Việc đăng xuất sẽ kết thúc phiên hiện tại trên thiết bị."
                ),
                (
                    "Quyền yêu cầu hỗ trợ",
                    "Nếu cần kiểm tra, chỉnh sửa hoặc xóa dữ liệu tài khoản, hãy liên hệ bộ phận hỗ trợ của ứng dụng để được hướng dẫn."
                )
            ]
        }
    }
}

private struct SettingsLegalDocumentView: View {
    let document: SettingsLegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Text(document.introduction)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)

                ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text(section.title)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(.primary)
                        Text(section.body)
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.vertical, AppSpacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appScreenBackground()
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
