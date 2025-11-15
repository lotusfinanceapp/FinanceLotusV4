import SwiftUI

// MARK: - TextField Placeholder Color Extension
struct PlaceholderColorModifier: ViewModifier {
    var placeholder: String
    @Binding var text: String
    var placeholderColor: Color

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(placeholderColor)
                    .allowsHitTesting(false)
            }
            content
        }
    }
}

extension View {
    func placeholder(
        _ placeholder: String,
        text: Binding<String>,
        color: Color = .colSecondaryText.opacity(0.6)
    ) -> some View {
        self.modifier(PlaceholderColorModifier(placeholder: placeholder, text: text, placeholderColor: color))
    }
}
