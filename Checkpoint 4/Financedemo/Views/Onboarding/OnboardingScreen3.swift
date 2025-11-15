import SwiftUI

// MARK: - Screen 3: Set Budget (Onboarding Only)
struct OnboardingScreen3: View {
    @Binding var showContent: Bool
    @Binding var budgetAmount: String
    @Binding var budgetSet: Bool // Track if budget has been set
    @Binding var showingCustomNumberPad: Bool
    @ObservedObject var dataManager: BudgetDataManager
    @State private var selectedCurrency = "USD"
    @State private var showingAlert = false
    @State private var animateElements = false

    let currencies = ["USD", "EUR", "CNY", "JPY", "GBP", "CAD"]

    private func currencyIconForCode(_ code: String) -> String {
        switch code {
        case "USD": return "dollarsign"
        case "EUR": return "eurosign"
        case "GBP": return "sterlingsign"
        case "CAD": return "dollarsign"
        case "JPY": return "yensign"
        case "CNY": return "yensign"
        default: return "dollarsign"
        }
    }

    private func isBudgetValid() -> Bool {
        if let amount = Double(budgetAmount) {
            return amount > 0
        }
        return false
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // === HEADER WITH ANIMATED ICON AND DECORATIVE ELEMENTS ===
                ZStack {
                    VStack(spacing: 20) {
                        // Large banknote icon with subtle animation
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.colAccent)
                            .padding(24)
                            .background(
                                Circle()
                                    .fill(Color.colAccent.opacity(0.12))
                            )
                            .modifier(FloatingAnimation(isAnimating: animateElements, delay: 0.1))
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        // Main text
                        VStack(spacing: 12) {
                            Text("Set Your Budget")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.colPrimaryText)
                                .multilineTextAlignment(.center)

                            Text("Your first step to financial confidence")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.colSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 280)
                .padding(.bottom, 40)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)

                // === BUDGET INPUT CARD WITH VISUAL FEEDBACK ===
                VStack(spacing: 20) {
                    // Currency selector as a beautiful card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 16))
                                .foregroundColor(.colAccent)

                            Text("Choose Your Currency")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.colPrimaryText)

                            Spacer()
                        }

                        Menu {
                            ForEach(currencies, id: \.self) { currency in
                                Button(action: {
                                    withAnimation {
                                        selectedCurrency = currency
                                    }
                                    UserDefaults.standard.set(currency, forKey: "selectedCurrency")
                                }) {
                                    HStack {
                                        Image(systemName: currencyIconForCode(currency))
                                            .font(.system(size: 16))
                                        Text(currency)
                                        if selectedCurrency == currency {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.colAccent)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.colAccent.opacity(0.2),
                                                Color.colAccent.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: currencyIconForCode(selectedCurrency))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.colAccent)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedCurrency)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.colPrimaryText)

                                    Text("Tap to change")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.colSecondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.colAccent)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.colCardBackground,
                                        Color.colCardBackground.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showContent)

                    // Budget amount input card with interactive feel
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#F59E0B"))

                            Text("Monthly Budget")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            // Show checkmark when budget is set
                            if budgetSet {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "#10B981"))
                                    Text("Set")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "#10B981"))
                                }
                            }
                        }

                        VStack(alignment: .center, spacing: 12) {
                            HStack(spacing: 4) {
                                Text(String.currencySymbol())
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.colSecondaryText)
                                    .opacity(0.7)

                                Text(budgetAmount.isEmpty ? "0.00" : budgetAmount)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.colPrimaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(isBudgetValid() ? (budgetSet ? "Budget confirmed" : "Tap to enter your budget") : "Invalid budget - enter a valid amount")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.colSecondaryText)
                                .opacity(0.6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colInputBackground)
                        )
                        .onTapGesture {
                            showingCustomNumberPad = true
                        }
                        .onChange(of: budgetAmount) { newValue in
                            // Validate budget - if it becomes 0 or invalid, mark as not set
                            if let amount = Double(newValue), amount > 0 {
                                budgetSet = true
                            } else {
                                budgetSet = false
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#F59E0B").opacity(0.06),
                                        Color(hex: "#F59E0B").opacity(0.02)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: showContent)
                    .animation(.easeInOut(duration: 0.3), value: budgetSet)

                    // Helper text
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            if isBudgetValid() {
                                Image(systemName: budgetSet ? "lightbulb.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(budgetSet ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))

                                Text(budgetSet ? "Budget set! You can adjust it later." : "A budget is required to continue.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.colSecondaryText)
                                    .lineSpacing(1)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#EF4444"))

                                Text("Budget must be greater than $0")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.colSecondaryText)
                                    .lineSpacing(1)
                            }

                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isBudgetValid() ?
                                (budgetSet ? Color(hex: "#10B981").opacity(0.08) : Color(hex: "#F59E0B").opacity(0.08)) :
                                Color(hex: "#EF4444").opacity(0.08)
                            )
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)
                    .animation(.easeInOut(duration: 0.3), value: budgetSet)
                    .animation(.easeInOut(duration: 0.3), value: isBudgetValid())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)

                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            // Load saved currency if available
            if let saved = UserDefaults.standard.string(forKey: "selectedCurrency") {
                selectedCurrency = saved
            }
            // Trigger floating animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateElements = true
            }
        }
        // === ERROR ALERT ===
        .alert("Invalid Amount", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid amount greater than \(String.currencySymbol())0")
                .foregroundColor(.colPrimaryText)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct OnboardingScreen3_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen3(
            showContent: .constant(true),
            budgetAmount: .constant(""),
            budgetSet: .constant(false),
            showingCustomNumberPad: .constant(false),
            dataManager: BudgetDataManager()
        )
        .previewDisplayName("Onboarding Screen 3 - Set Budget")
    }
}
#endif
