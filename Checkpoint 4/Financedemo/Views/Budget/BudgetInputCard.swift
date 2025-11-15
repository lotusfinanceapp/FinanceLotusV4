import SwiftUI

// MARK: - Budget Input Card Component - ELEVATED ANIMATED INPUT CARD
struct BudgetInputCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let onTap: (() -> Void)?

    @State private var isPressed = false
    @State private var isFocused = false

    init(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType, onTap: (() -> Void)? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card title
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.colPrimaryText)
            
            // Input field
            TextField("", text: $text, onEditingChanged: { editing in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = editing
                }
            })
            .placeholder(placeholder, text: $text)
            .onTapGesture {
                if let onTap = onTap {
                    onTap()
                }
            }
            .onChange(of: text) { newValue in
                // Prevent multiple decimal points for decimal input
                if keyboardType == .decimalPad {
                    let filtered = filterDecimalInput(newValue)
                    if filtered != newValue {
                        text = filtered
                    }
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .font(.body)
            .foregroundColor(.colInputText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.colInputBackground) // Lighter green for input field
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? Color.colIconPrimary : Color.gray.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .keyboardType(keyboardType)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground) // Light green card background
                .shadow(
                    color: .black.opacity(isPressed ? 0.15 : 0.08),
                    radius: isPressed ? 12 : 8,
                    x: 0,
                    y: isPressed ? 6 : 4
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            if let onTap = onTap {
                onTap()
            } else {
                // Default behavior - dismiss keyboard
                hideKeyboard()
            }
            
            // Animate press effect
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func filterDecimalInput(_ input: String) -> String {
        // Allow only numbers and one decimal point
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let filtered = input.components(separatedBy: allowedCharacters.inverted).joined()
        
        // Split by decimal point
        let components = filtered.components(separatedBy: ".")
        
        // If no decimal points, return as is
        if components.count <= 1 {
            return filtered
        }
        
        // If multiple decimal points, keep only the first one
        if components.count > 2 {
            return components[0] + "." + components[1]
        }
        
        // If exactly one decimal point, limit to 2 decimal places
        if components.count == 2 {
            let wholePart = components[0]
            let decimalPart = String(components[1].prefix(2)) // Limit to 2 decimal places
            return wholePart + "." + decimalPart
        }
        
        return filtered
    }
}

// MARK: - Preview
#if DEBUG
struct BudgetInputCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BudgetInputCard(
                title: "Budget Category",
                placeholder: "e.g., Groceries, Entertainment",
                text: .constant("Shopping"),
                keyboardType: .default
            )
            
            BudgetInputCard(
                title: "Budget Amount \(String.currencySymbol())",
                placeholder: "0.00",
                text: .constant("100.00"),
                keyboardType: .decimalPad
            )
        }
        .padding()
        .background(Color.colBackground)
        .previewDisplayName("Budget Input Cards")
    }
}
#endif
