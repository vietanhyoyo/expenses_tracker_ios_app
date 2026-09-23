import SwiftUI

struct SettingsView: View {
    let factory: any ViewModelFactory
    @Bindable var session: SessionViewModel

    var body: some View {
        NavigationStack {
            List {
                managementSection
                accountSection
                dataSection
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
                LabeledContent("Mã người dùng", value: String(user.id))
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
            NavigationLink {
                BudgetsView(factory: factory)
            } label: {
                SettingsRow(title: "Ngân sách", subtitle: "Giới hạn chi tiêu tháng", icon: "gauge.with.dots.needle.50percent", color: AppTheme.gold)
            }
        }
    }

    private var dataSection: some View {
        Section("Dữ liệu") {
            LabeledContent {
                Text("Máy chủ + thiết bị").foregroundStyle(.secondary)
            } label: {
                Label("Lưu trữ", systemImage: "internaldrive.fill")
            }
            LabeledContent {
                Text("Việt Nam Đồng (₫)").foregroundStyle(.secondary)
            } label: {
                Label("Đơn vị tiền", systemImage: "banknote.fill")
            }
        }
    }

    private var privacySection: some View {
        Section {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                AppIconBadge(icon: "lock.shield.fill", color: AppTheme.teal)
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("Phiên đăng nhập an toàn")
                        .font(AppTypography.cardTitle)
                    Text("Token được lưu trong Keychain. Giao dịch, danh mục và Tổng quan được đồng bộ qua API; tài khoản và ngân sách vẫn lưu trên thiết bị.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, AppSpacing.xxxSmall)
        }
    }
}
