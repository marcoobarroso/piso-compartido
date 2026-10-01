import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(RTheme.primaryForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isDestructive ? RTheme.destructive : RTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.md))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(RTheme.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RTheme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.md))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var rPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var rDestructive: PrimaryButtonStyle { PrimaryButtonStyle(isDestructive: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var rSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

struct RTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RTheme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.sm))
            .foregroundStyle(RTheme.foreground)
    }
}
