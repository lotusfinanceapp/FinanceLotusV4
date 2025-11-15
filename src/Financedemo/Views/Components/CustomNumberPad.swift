import SwiftUI

// MARK: - Custom Number Pad Component
struct CustomNumberPad: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    @State private var slideOffset: CGFloat = 800
    @State private var deleteTimer: Timer?
    @State private var pressedButton: String? = nil
    @State private var showCursor = true
    @State private var hasDecimal = false
    @State private var presetAmountsNegative = false // Toggle between +/- for preset amounts

    private let numbers = [
        ["1", "2", "3", "⌫"],
        ["4", "5", "6", "±"],
        ["7", "8", "9", ""],
        [".", "0", "🗑️", "✓"]
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.2)
                    .onTapGesture {
                        dismissPad()
                    }

                VStack(spacing: 0) {
                    Spacer()

                    // Number pad container
                    VStack(spacing: 0) {
                    // Current amount display
                    HStack {
                        Text(String.currencySymbol())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colSecondaryText)
                            .background(Color.clear)

                        HStack(spacing: 2) {
                            Text(text.isEmpty ? "0" : formatWithCommas(text))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.colPrimaryText)
                                .id(text) // Force view refresh without animation

                            Rectangle()
                                .fill(Color.colAccent)
                                .frame(width: 2, height: 24)
                                .opacity(showCursor ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
                        }

                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.colCardBackground)

                    // Quick preset amounts - Design 2 with Design 1 colors
                    HStack(spacing: 10) {
                        Spacer()
                        ForEach([1, 5, 20], id: \.self) { amount in
                            Button(action: { addPresetAmount(amount) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: presetAmountsNegative ? "minus" : "plus")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text("\(String.currencySymbol())\(amount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.colOnAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.colAccent, Color.colAccent.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color.colCardBackground)

                    // Number buttons grid (4x3)
                    VStack(spacing: 12) {
                        ForEach(Array(numbers.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 12) {
                                ForEach(Array(row.enumerated()), id: \.offset) { colIndex, number in
                                    if number.isEmpty {
                                        // Empty space
                                        Spacer()
                                            .frame(width: 60, height: 60)
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(getButtonColor(for: number))
                                                .frame(width: 60, height: 60)

                                            if number == "⌫" {
                                                Image(systemName: "delete.left")
                                                    .font(.title3)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                            } else if number == "🗑️" {
                                                Image(systemName: "trash")
                                                    .font(.title3)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.red)
                                            } else if number == "✓" {
                                                Image(systemName: "checkmark")
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.colOnAccent)
                                            } else if number == "±" {
                                                Image(systemName: "plus.forwardslash.minus")
                                                    .font(.title3)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                            } else {
                                                Text(number)
                                                    .font(.title3)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                            }
                                        }
                                        .scaleEffect(pressedButton == number ? 0.9 : 1.0)
                                        .opacity(pressedButton == number ? 0.7 : 1.0)
                                        .animation(.easeInOut(duration: 0.15), value: pressedButton == number)
                                        .onTapGesture {
                                            buttonTapped(number)
                                        }
                                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                                            // Long press completed - start continuous delete
                                            if number == "⌫" {
                                                startContinuousDelete()
                                            }
                                        } onPressingChanged: { pressing in
                                            if pressing {
                                                pressedButton = number
                                            } else {
                                                pressedButton = nil
                                                if number == "⌫" {
                                                    // Always stop when finger is lifted
                                                    stopContinuousDelete()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 10))
                }
                .background(Color.colCardBackground)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                .offset(y: slideOffset)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 1.0)) {
                slideOffset = 0
            }
            // Start cursor blinking
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                showCursor = false
            }
        }
    }

    private func buttonTapped(_ number: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        switch number {
        case "⌫":
            // Delete last character
            if !text.isEmpty {
                text.removeLast()
                // Update decimal state
                hasDecimal = text.contains(".")
            }
        case "🗑️":
            text = ""
            hasDecimal = false
        case "✓":
            dismissPad()
        case "±":
            // Toggle preset amounts between positive and negative
            presetAmountsNegative.toggle()
        case ".":
            // Add decimal point if not already present
            if !hasDecimal {
                if text.isEmpty {
                    text = "0."
                } else {
                    text += "."
                }
                hasDecimal = true
            }
        default:
            // Add digit
            if let _ = Int(number) {
                // Limit decimal places to 2
                if hasDecimal {
                    let parts = text.split(separator: ".")
                    if parts.count > 1 && parts[1].count >= 2 {
                        return // Already have 2 decimal places
                    }
                }

                // Prevent unreasonably long numbers
                if text.count >= 12 {
                    return
                }

                if text == "0" && !hasDecimal {
                    text = number
                } else {
                    text += number
                }
            }
        }
    }

    private func addPresetAmount(_ amount: Int) {
        let currentValue = Double(text) ?? 0
        let amountToAdd = presetAmountsNegative ? -Double(amount) : Double(amount)
        let newValue = max(0, currentValue + amountToAdd) // Prevent going below 0

        // Format the new value
        if newValue.truncatingRemainder(dividingBy: 1) == 0 {
            // No decimal places
            text = String(format: "%.0f", newValue)
            hasDecimal = false
        } else {
            // Has decimal places
            text = String(format: "%.2f", newValue)
            hasDecimal = true
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    // Helper function to format cents (integer) to dollar string with decimal
    private func formatCentsToString(_ cents: Int) -> String {
        if cents == 0 {
            return ""
        }
        let dollars = cents / 100
        let remainingCents = cents % 100

        if dollars == 0 {
            return String(format: "0.%02d", remainingCents)
        } else {
            return String(format: "%d.%02d", dollars, remainingCents)
        }
    }

    private func getButtonColor(for number: String) -> Color {
        switch number {
        case "✓":
            return .colAccent
        case "🗑️":
            return Color.red.opacity(0.1)
        case "⌫", "±":
            return Color.colSecondaryText.opacity(0.1)
        default:
            return Color.colInputBackground
        }
    }

    private func startContinuousDelete() {
        guard text.count > 0 else { return }

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Delete first character immediately
        if !text.isEmpty {
            text.removeLast()
            hasDecimal = text.contains(".")
        }

        // Start timer for continuous deletion
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !self.text.isEmpty {
                self.text.removeLast()
                self.hasDecimal = self.text.contains(".")
                // Light haptic feedback for each deletion
                let softFeedback = UIImpactFeedbackGenerator(style: .light)
                softFeedback.impactOccurred()
            } else {
                self.stopContinuousDelete()
            }
        }
    }

    private func stopContinuousDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    private func dismissPad() {
        stopContinuousDelete() // Stop any ongoing deletion

        withAnimation(.spring(response: 0.5, dampingFraction: 1.0)) {
            slideOffset = 800
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPresented = false
            onDismiss()
        }
    }

    // Format number string with commas
    private func formatWithCommas(_ numberString: String) -> String {
        // Split by decimal point
        let parts = numberString.split(separator: ".", omittingEmptySubsequences: false)
        let integerPart = String(parts[0])

        // Add commas to integer part
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        if let number = Double(integerPart),
           let formatted = formatter.string(from: NSNumber(value: number)) {
            // If there's a decimal part, append it
            if parts.count > 1 {
                return formatted + "." + parts[1]
            } else {
                return formatted
            }
        }

        return numberString
    }
}

// MARK: - Custom Button Style
struct NumberPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct CustomNumberPad_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.colBackground.ignoresSafeArea()

            CustomNumberPad(
                text: .constant("123.45"),
                isPresented: .constant(true),
                onDismiss: {}
            )
        }
    }
}