import SwiftUI

struct CategoryFormView: View {
    @State var viewModel: CategoryFormViewModel
    @Environment(\.dismiss) private var dismiss

    private let icons = [
        "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill",
        "doc.text.fill", "cross.case.fill", "book.fill", "banknote.fill",
        "gift.fill", "star.fill", "square.grid.2x2.fill"
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
        Section("Biểu tượng") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 5),
                spacing: AppSpacing.small
            ) {
                ForEach(icons, id: \.self) { value in
                    iconButton(value)
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

    private func iconButton(_ value: String) -> some View {
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
        .accessibilityLabel(value)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        Task {
            if await viewModel.save() { dismiss() }
        }
    }
}
