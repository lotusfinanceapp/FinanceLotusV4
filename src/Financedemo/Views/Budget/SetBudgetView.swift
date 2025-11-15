import SwiftUI

// MARK: - Set Budget Screen - INITIAL SETUP SCREEN
struct SetBudgetView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var budgetAmount: String = ""      // User input for budget amount
    @State private var showingAlert = false           // Controls error alert display
    @State private var showCards = false              // Controls card entrance animation
    @State private var showingCustomNumberPad = false // Controls custom number pad
    @State private var showingApplyToAllMonthsAlert = false // Ask about applying to all months
    @State private var pendingBudgetAmount: Double? = nil // Store pending budget change
    @State private var selectedCurrency = "USD"
    @Environment(\.presentationMode) var presentationMode

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

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // === HEADER SECTION WITH ANIMATED ENTRANCE ===
                    VStack(spacing: 16) {
                        // Banknote icon
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.colAccent)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            .opacity(showCards ? 1.0 : 0.0)
                            .offset(y: showCards ? 0 : 20)

                        // Main heading text
                        Text("Set Your Monthly Budget")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.colPrimaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.bottom, 12)
                            .opacity(showCards ? 1.0 : 0.0)
                            .offset(y: showCards ? 0 : 20)

                        // Subtitle text
                        Text("Start tracking your expenses by setting a monthly budget. You can always adjust it later.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.colSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.bottom, 40)
                            .opacity(showCards ? 1.0 : 0.0)
                            .offset(y: showCards ? 0 : 20)
                    }
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showCards)
                    .padding(.horizontal, 20)

                    // === CURRENCY SELECTOR CARD ===
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Preferred Currency")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Menu {
                            ForEach(currencies, id: \.self) { currency in
                                Button(action: {
                                    selectedCurrency = currency
                                    UserDefaults.standard.set(currency, forKey: "selectedCurrency")
                                }) {
                                    HStack {
                                        Image(systemName: currencyIconForCode(currency))
                                            .font(.system(size: 16))
                                        Text(currency)
                                        if selectedCurrency == currency {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 15) {
                                Circle()
                                    .fill(Color.colAccent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: currencyIconForCode(selectedCurrency))
                                            .font(.system(size: 20))
                                            .foregroundColor(.colAccent)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Currency")
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)

                                    Text(selectedCurrency)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.colSecondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colInputBackground)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .opacity(showCards ? 1.0 : 0.0)
                    .offset(y: showCards ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showCards)

                    // === BUDGET AMOUNT CARD ===
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Monthly Budget")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Button(action: {
                            showingCustomNumberPad = true
                        }) {
                            HStack {
                                Text(String.currencySymbol())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colSecondaryText)

                                Text(budgetAmount.isEmpty ? "0.00" : budgetAmount)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colInputBackground)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .opacity(showCards ? 1.0 : 0.0)
                    .offset(y: showCards ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showCards)

                        Spacer().frame(height: 50)
                    }
                }

                // === SET BUDGET BUTTON ===
                VStack(spacing: 12) {
                    Button(action: setBudget) {
                        HStack {
                            Text("Set Budget")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colAccent)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.colBackground)
                // === TRIGGER DRAMATIC ENTRANCE ANIMATIONS ===
                .onAppear {
                    print("\n[SetBudgetView] onAppear - View loaded")
                    // Load existing budget if editing
                    if let existingBudget = dataManager.budget {
                        print("[SetBudgetView] Loading existing budget: $\(existingBudget.amount)")
                        budgetAmount = String(format: "%.2f", existingBudget.amount)
                    } else {
                        print("[SetBudgetView] No existing budget found")
                    }
                    withAnimation {
                        showCards = true
                    }
                }
                // === ERROR ALERT ===
                .alert("Invalid Amount", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please enter a valid amount greater than \(String.currencySymbol())0")
                        .foregroundColor(.colPrimaryText)
                }
                // === APPLY TO ALL MONTHS ALERT ===
                .alert("Apply to All Months?", isPresented: $showingApplyToAllMonthsAlert) {
                    Button("This Month Only", role: .cancel) {
                        if let amount = pendingBudgetAmount {
                            applyBudgetChange(amount, applyToAllMonths: false)
                        }
                    }
                    Button("All Previous Months") {
                        if let amount = pendingBudgetAmount {
                            applyBudgetChange(amount, applyToAllMonths: true)
                        }
                    }
                } message: {
                    Text("Would you like to apply this budget change to all previous months, or just this month forward?")
                }
                // === TOOLBAR WITH BACK BUTTON ===
                .toolbarBackground(Color.colBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.colBackButtonIcon)
                        }
                    }
                }
            }

                // === CUSTOM NUMBER PAD OVERLAY ===
                if showingCustomNumberPad {
                    CustomNumberPad(
                        text: $budgetAmount,
                        isPresented: $showingCustomNumberPad,
                        onDismiss: {
                            showingCustomNumberPad = false
                        }
                    )
                    .zIndex(1000)
                }
            }
        }
    }

    // === BUDGET VALIDATION AND CREATION ===
    private func setBudget() {
        print("\n[SetBudgetView] setBudget() called")
        print("[SetBudgetView] budgetAmount = \(budgetAmount)")

        // Validate amount is a positive number
        guard let amount = Double(budgetAmount), amount > 0 else {
            print("[SetBudgetView] Invalid amount, showing alert")
            showingAlert = true // Show error alert
            return
        }

        print("[SetBudgetView] Valid amount: $\(amount)")

        // If editing existing budget, ask about applying to all months
        if dataManager.budget != nil {
            print("[SetBudgetView] Existing budget found, showing alert")
            pendingBudgetAmount = amount
            showingApplyToAllMonthsAlert = true
        } else {
            // First time setting budget, just create it
            print("[SetBudgetView] First time setting budget")
            dataManager.setBudget(amount, period: .monthly)
        }
    }

    private func applyBudgetChange(_ amount: Double, applyToAllMonths: Bool) {
        print("\n[SetBudgetView] applyBudgetChange called")
        print("[SetBudgetView] amount: $\(amount)")
        print("[SetBudgetView] applyToAllMonths: \(applyToAllMonths)")

        // Update budget with the user's choice
        dataManager.setBudget(amount, period: .monthly, applyToAllMonths: applyToAllMonths)

        print("[SetBudgetView] Dismissing view")
        // Dismiss
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
#if DEBUG
struct SetBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        SetBudgetView(dataManager: BudgetDataManager())
            .previewDisplayName("Set Budget Screen")
    }
}
#endif