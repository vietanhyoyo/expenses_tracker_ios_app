import SwiftUI
import UIKit

struct AmountTextField: View {
    @Binding var text: String
    var accentColor: Color = AppTheme.teal

    @State private var isFocused = false

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.xSmall) {
                AppIconBadge(
                    icon: "banknote.fill",
                    color: accentColor,
                    size: 30
                )

                Text("Số tiền")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppTheme.navy)

                Spacer()

                Text("VND")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(
                        accentColor.opacity(0.1),
                        in: Capsule(style: .continuous)
                    )
            }

            VietnameseMoneyTextField(
                text: $text,
                font: Self.amountFont,
                textAlignment: .center,
                textColor: UIColor(AppTheme.navy),
                adjustsFontSizeToFitWidth: true,
                onFocusChanged: { isFocused = $0 }
            )
            .frame(height: 58)
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.medium)
        .background(
            AppTheme.elevatedSurface,
            in: RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(
                    isFocused ? accentColor.opacity(0.75) : AppTheme.separator,
                    lineWidth: isFocused ? 1.5 : 0.5
                )
        }
        .shadow(color: AppTheme.navy.opacity(0.07), radius: 14, y: 6)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: accentColor)
    }

    private static let amountFont: UIFont = {
        let font = UIFont.systemFont(ofSize: 42, weight: .bold)
        let descriptor = font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor
        return UIFont(descriptor: descriptor, size: 42)
    }()
}

struct VietnameseMoneyTextField: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textAlignment: NSTextAlignment = .natural
    var textColor: UIColor = .label
    var adjustsFontSizeToFitWidth = false
    var onFocusChanged: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = "0"
        textField.accessibilityLabel = "Số tiền, Việt Nam đồng"
        configure(textField)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        configure(textField)

        if textField.text != text {
            textField.text = text
        }
    }

    private func configure(_ textField: UITextField) {
        textField.font = font
        textField.textAlignment = textAlignment
        textField.textColor = textColor
        textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        textField.minimumFontSize = adjustsFontSizeToFitWidth ? 24 : 0
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: VietnameseMoneyTextField

        init(parent: VietnameseMoneyTextField) {
            self.parent = parent
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard
                let currentValue = textField.text,
                let textRange = Range(range, in: currentValue)
            else {
                return false
            }

            let proposedValue = currentValue.replacingCharacters(in: textRange, with: string)
            let formattedValue = AppFormatters.vietnameseMoneyInput(proposedValue)

            textField.text = formattedValue
            parent.text = formattedValue
            moveCursorToEnd(of: textField)
            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChanged(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChanged(false)
        }

        private func moveCursorToEnd(of textField: UITextField) {
            guard let endPosition = textField.position(
                from: textField.beginningOfDocument,
                offset: textField.text?.count ?? 0
            ) else {
                return
            }
            textField.selectedTextRange = textField.textRange(
                from: endPosition,
                to: endPosition
            )
        }
    }
}
