import SwiftUI

// MARK: - Set Budget Screen - INITIAL SETUP SCREEN
struct SetBudgetView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var budgetAmount: String = ""      // User input for budget amount
    @State private var selectedPeriod: BudgetPeriod = .monthly // Selected budget period
    @State private var showingAlert = false           // Controls error alert display
    @State private var showCards = false              // Controls card entrance animation
    
    var body: some View {
        VStack(spacing: 30) {
            // === TOP SPACING ===
            Color.clear.frame(height: 80) // Space for fixed logo
                
                // === HEADER SECTION WITH ANIMATED ENTRANCE ===
                VStack(spacing: 20) {
                    // Target icon (edit color with colTargetIcon)
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.colTargetIcon)
                        .scaleEffect(1.0)
                        .rotationEffect(.degrees(0))
                        .opacity(1.0)
                        .animation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0.3).delay(0.1), value: true)
                        .onAppear {
                            withAnimation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0.3).delay(0.1)) {
                                // Animation happens on appear
                            }
                        }
                        
                    // Main heading text
                    Text("Set Your Budget")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle text
                    Text("Choose your budget amount and time period")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                }
                    
                // === INPUT CARDS SECTION WITH STAGGERED ENTRANCE ===
                VStack(spacing: 25) {
                    // === BUDGET PERIOD SELECTION ===
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Budget Period")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                        
                        HStack(spacing: 12) {
                            ForEach(BudgetPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedPeriod = period
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: period.icon)
                                            .font(.title)
                                            .fontWeight(.semibold)
                                            .foregroundColor(selectedPeriod == period ? .white : .colPrimaryText)
                                        
                                        Text(period.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedPeriod == period ? .white : .colPrimaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedPeriod == period ? Color.colAccent : Color.colInputBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedPeriod == period ? Color.colAccent : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .opacity(showCards ? 1.0 : 0.0)
                    .offset(y: showCards ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showCards)
                    
                    // === BUDGET AMOUNT CARD ===
                    BudgetInputCard(
                        title: "Budget Amount $",
                        placeholder: "0.00",
                        text: $budgetAmount,
                        keyboardType: .decimalPad
                    )
                    .opacity(showCards ? 1.0 : 0.0)
                    .offset(y: showCards ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showCards)
                }
                
                // === SET BUDGET BUTTON WITH BOUNCE ANIMATION ===
                Button(action: setBudget) {
                    Text("Set Budget!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.colButton)
                        .cornerRadius(12)
                }
                .disabled(budgetAmount.isEmpty) // Button disabled if amount field empty
                .opacity(showCards ? 1.0 : 0.0)
                .offset(y: showCards ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showCards)
                    
                Spacer() // Pushes content to top
            }
            // === SCREEN STYLING ===
            .padding(.horizontal)
            .padding(.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill available space
            .background(Color.colBackground) // Screen background
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0) // Respects safe area for camera/status bar
            }
            // === TRIGGER DRAMATIC ENTRANCE ANIMATIONS ===
            .onAppear {
                withAnimation {
                    showCards = true
                }
            }
            // === ERROR ALERT ===
            .alert("Invalid Amount", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid amount greater than $0")
                    .foregroundColor(.colPrimaryText)
            }
    }
    
    // === BUDGET VALIDATION AND CREATION ===
    private func setBudget() {
        // Validate amount is a positive number
        guard let amount = Double(budgetAmount), amount > 0 else {
            showingAlert = true // Show error alert
            return
        }
        
        // Create budget and switch to main app
        dataManager.setBudget(amount, period: selectedPeriod)
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