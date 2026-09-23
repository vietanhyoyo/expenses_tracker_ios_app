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

    var body: some View {
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
