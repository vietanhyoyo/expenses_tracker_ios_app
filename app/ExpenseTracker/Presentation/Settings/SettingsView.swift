import SwiftUI

struct SettingsView: View {
    let factory: any ViewModelFactory

    var body: some View {
        NavigationStack {
            List {
                managementSection
                dataSection
                privacySection
            }
            .appFormStyle()
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
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
                Text("Chỉ trên thiết bị").foregroundStyle(.secondary)
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
                    Text("Riêng tư từ thiết kế")
                        .font(AppTypography.cardTitle)
                    Text("Dữ liệu được lưu cục bộ bằng SwiftData và không được gửi lên máy chủ.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, AppSpacing.xxxSmall)
        }
    }
}
