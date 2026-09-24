import SwiftUI

struct CategoryFormView: View {
    @State var viewModel: CategoryFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var failureMessage: String?

    private let onSuccess: ((String) -> Void)?

    init(
        viewModel: CategoryFormViewModel,
        onSuccess: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSuccess = onSuccess
    }

    private let icons = [
        // Food and transport
        "fork.knife", "mug.fill", "takeoutbag.and.cup.and.straw.fill",
        "car.fill", "car.side.fill", "bus.fill", "tram.fill", "bicycle",
        "airplane", "fuelpump.fill",
        // Shopping and entertainment
        "bag.fill", "cart.fill", "basket.fill", "tshirt.fill",
        "gamecontroller.fill", "film.fill", "music.note", "tv.fill",
        "ticket.fill", "sparkles",
        // Home and bills
        "house.fill", "building.2.fill", "bolt.fill", "wifi",
        "phone.fill", "doc.text.fill", "wrench.and.screwdriver.fill",
        "briefcase.fill", "creditcard.fill", "banknote.fill",
        // Health, education, and other
        "cross.case.fill", "heart.fill", "figure.run", "dumbbell.fill",
        "book.fill", "graduationcap.fill", "gift.fill", "star.fill",
        "pawprint.fill", "leaf.fill", "person.2.fill", "square.grid.2x2.fill"
    ]

    @ViewBuilder
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadForm
        } else {
            iPhoneForm
        }
    }

    private var iPhoneForm: some View {
        NavigationStack {
            Form {
                detailsSection
                colorSection
                iconSection
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        ErrorBanner(message: errorMessage)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .appFormStyle()
            .navigationTitle(viewModel.isEditing ? "Sửa danh mục" : "Danh mục mới")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(isSaveDisabled: !viewModel.canSave, onSave: save)
        }
        .errorToast(message: $failureMessage)
    }

    private var iPadForm: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    iPadDetailsCard
                    iPadColorCard
                    iPadIconCard

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                }
                .padding(AppSpacing.xLarge)
            }
            .background(AppTheme.background)
            .navigationTitle(viewModel.isEditing ? "Sửa danh mục" : "Danh mục mới")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(isSaveDisabled: !viewModel.canSave, onSave: save)
        }
        .frame(width: 700, height: 700)
        .modifier(CategoryFormIPadPresentationModifier())
        .errorToast(message: $failureMessage)
    }

    private var iPadDetailsCard: some View {
        @Bindable var viewModel = viewModel

        return iPadSectionCard(title: "Thông tin") {
            Picker("Loại", selection: $viewModel.type) {
                ForEach(TransactionType.allCases, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isEditing)
            .onChange(of: viewModel.type) { _, _ in
                viewModel.typeChanged()
            }

            Divider()

            TextField("Tên danh mục", text: $viewModel.name)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .frame(height: 50)
                .background(
                    AppTheme.surface,
                    in: RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 0.5)
                }
        }
    }

    private var iPadColorCard: some View {
        iPadSectionCard(title: "Màu sắc") {
            ColorPicker(
                "Màu danh mục",
                selection: colorSelection,
                supportsOpacity: false
            )
            .font(AppTypography.bodyEmphasis)
            .frame(minHeight: 44)
        }
    }

    private var iPadIconCard: some View {
        @Bindable var viewModel = viewModel

        return iPadSectionCard(title: "Biểu tượng") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: AppSpacing.xxSmall
            ) {
                ForEach(icons, id: \.self) { value in
                    iconButton(value, viewModel: viewModel)
                }
            }
        }
    }

    private func iPadSectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(.primary)

            content()
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.elevatedSurface,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        }
        .shadow(color: AppTheme.navy.opacity(0.05), radius: 10, y: 4)
    }

    @ViewBuilder
    private var detailsSection: some View {
        @Bindable var viewModel = viewModel
        Section {
            Picker("Loại", selection: $viewModel.type) {
                ForEach(TransactionType.allCases, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isEditing)
            .onChange(of: viewModel.type) { _, _ in
                viewModel.typeChanged()
            }
            TextField("Tên danh mục", text: $viewModel.name)
        }
    }

    private var colorSection: some View {
        Section("Màu sắc") {
            ColorPicker(
                "Màu danh mục",
                selection: colorSelection,
                supportsOpacity: false
            )
        }
    }

    private var iconSection: some View {
        @Bindable var viewModel = viewModel
        return Section("Biểu tượng") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 5),
                spacing: AppSpacing.small
            ) {
                ForEach(icons, id: \.self) { value in
                    iconButton(value, viewModel: viewModel)
                }
            }
            .padding(.vertical, AppSpacing.xxSmall)
        }
    }

    private var selectedColor: Color {
        Color(hex: viewModel.colorHex)
    }

    /// Adapts the ViewModel's hex string to the `Color` used by `ColorPicker`.
    private var colorSelection: Binding<Color> {
        Binding(
            get: { Color(hex: viewModel.colorHex) },
            set: { viewModel.colorHex = $0.hexRGB }
        )
    }

    private func iconButton(
        _ value: String,
        viewModel: CategoryFormViewModel
    ) -> some View {
        let isSelected = viewModel.icon == value

        return Button { viewModel.icon = value } label: {
            AppIconBadge(
                icon: value,
                color: isSelected ? .white : selectedColor,
                size: 44,
                backgroundColor: isSelected ? selectedColor : AppTheme.surface,
                borderColor: isSelected ? selectedColor : AppTheme.separator,
                borderWidth: 0.5,
                iconScale: 0.46
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(Rectangle())
        .accessibilityLabel(value)
        .accessibilityValue(isSelected ? "Đang chọn" : "Chưa chọn")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        Task {
            if await viewModel.save() {
                onSuccess?(
                    viewModel.isEditing
                        ? "Đã cập nhật danh mục thành công"
                        : "Đã thêm danh mục thành công"
                )
                dismiss()
            } else if let errorMessage = viewModel.errorMessage {
                failureMessage = errorMessage
            }
        }
    }
}

private struct CategoryFormIPadPresentationModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .presentationSizing(.fitted)
                .presentationDragIndicator(.visible)
        } else {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
