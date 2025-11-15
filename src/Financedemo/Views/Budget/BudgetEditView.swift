import SwiftUI

// MARK: - Budget Edit View - EDIT EXISTING BUDGET
struct BudgetEditView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var isPresented: Bool
    
    @State private var budgetAmount: String = ""
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showElements = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // === TOP SPACING ===
                    Color.clear.frame(height: 80) // Space for fixed logo
                    
                    // === HEADER SECTION ===
                    VStack(spacing: 20) {
                        // Target icon
                        Image(systemName: "target")
                            .font(.system(size: 50))
                            .foregroundColor(.colTargetIcon)
                            .opacity(showElements ? 1.0 : 0.0)
                            .scaleEffect(showElements ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.5), value: showElements)
                            
                        // Main heading text
                        Text("Edit Your Budget")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)
                            .multilineTextAlignment(.center)
                        
                        // Current budget info
                        if let budget = dataManager.budget {
                            VStack(spacing: 8) {
                                Text("Current: \(budget.amount.formattedCurrency())")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colAccent)
                                
                                Text("\(budget.period.rawValue) budget")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)
                            }
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                        
                    // === INPUT CARDS SECTION ===
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
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPeriod = period
                                        }
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
                        .opacity(showElements ? 1.0 : 0.0)
                        .offset(y: showElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                        
                        // === BUDGET AMOUNT CARD ===
                        BudgetInputCard(
                            title: "New Budget Amount \(String.currencySymbol())",
                            placeholder: "0.00",
                            text: $budgetAmount,
                            keyboardType: .decimalPad
                        )
                        .opacity(showElements ? 1.0 : 0.0)
                        .offset(y: showElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                    }
                    
                    // === ACTION BUTTONS ===
                    VStack(spacing: 15) {
                        // Update Budget Button
                        Button(action: updateBudget) {
                            Text("Update Budget")
                                .font(.headline)
                                .foregroundColor(.colOnAccent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(budgetAmount.isEmpty)
                        .opacity(showElements ? 1.0 : 0.0)
                        .offset(y: showElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: showElements)
                    }
                    
                    // Add bottom padding for safe scrolling
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal)
            }
            .background(Color.colBackground.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colBackButtonIcon)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Budget")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
        .onAppear {
            // Configure navigation bar appearance to prevent white background
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            // Initialize with current budget values
            if let budget = dataManager.budget {
                budgetAmount = String(format: "%.2f", budget.amount)
                selectedPeriod = budget.period
            }
            
            showElements = false
            withAnimation {
                showElements = true
            }
            
            // Set global background color
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.backgroundColor = UIColor(Color.colBackground)
            }
        }
        .alert("Alert", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // === UPDATE BUDGET ===
    private func updateBudget() {
        // Validate amount
        guard let amount = Double(budgetAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount greater than \(String.currencySymbol())0"
            showingAlert = true
            return
        }
        
        // Update budget in data manager
        dataManager.setBudget(amount, period: selectedPeriod)
        
        // Close the view
        isPresented = false
    }
}

// MARK: - Preview
#if DEBUG
struct BudgetEditView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.setBudget(500.0, period: .monthly)
        return BudgetEditView(dataManager: dataManager, isPresented: .constant(true))
            .previewDisplayName("Budget Edit Screen")
    }
}
#endif
