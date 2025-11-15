import SwiftUI

// MARK: - Edit Month Budget View - EDIT BUDGET FOR A SPECIFIC MONTH
struct EditMonthBudgetView: View {
    @ObservedObject var dataManager: BudgetDataManager
    let selectedMonth: Date
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var budgetAmount = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingCustomNumberPad = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // === HEADER SECTION ===
                        VStack(spacing: 20) {
                            Image(systemName: "calendar")
                                .font(.system(size: 50))
                                .foregroundColor(.colAccent)

                            Text("Edit Monthly Budget")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.colPrimaryText)

                            Text(monthYearString)
                                .font(.subheadline)
                                .foregroundColor(.colSecondaryText)
                        }
                        .padding(.top, 30)

                        // === BUDGET INPUT SECTION ===
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Budget Amount")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Button(action: {
                                showingCustomNumberPad = true
                            }) {
                                HStack {
                                    Text(String.currencySymbol())
                                        .foregroundColor(.colSecondaryText)
                                    Text(budgetAmount.isEmpty ? "0.00" : budgetAmount)
                                        .foregroundColor(.colPrimaryText)
                                    Spacer()
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.colInputBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.colAccent.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)

                        // === UPDATE BUTTON ===
                        Button(action: updateBudget) {
                            HStack {
                                Text("Update Budget")
                                    .font(.headline)
                                    .foregroundColor(.colOnAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .disabled(budgetAmount.isEmpty)
                        .opacity(budgetAmount.isEmpty ? 0.6 : 1.0)

                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.colBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .onAppear {
                budgetAmount = String(format: "%.2f", dataManager.budget?.amount ?? 0)
            }
            .overlay(
                Group {
                    if showingCustomNumberPad {
                        CustomNumberPad(
                            text: $budgetAmount,
                            isPresented: $showingCustomNumberPad,
                            onDismiss: {}
                        )
                    }
                }
            )
            .alert("Invalid Amount", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
                    .foregroundColor(.colPrimaryText)
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func updateBudget() {
        guard let amount = Double(budgetAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount greater than $0"
            showingAlert = true
            return
        }

        // Update budget for this specific month only
        let calendar = Calendar.current
        let month = calendar.component(.month, from: selectedMonth)
        let year = calendar.component(.year, from: selectedMonth)

        // Find and update existing budget for this month, or create a new one
        if let existingIndex = dataManager.budgets.firstIndex(where: { $0.month == month && $0.year == year }) {
            // Remove old budget and add updated one with the same period and dateCreated
            let oldBudget = dataManager.budgets[existingIndex]
            let updatedBudget = Budget(
                amount: amount,
                period: oldBudget.period,
                month: month,
                year: year,
                dateCreated: oldBudget.dateCreated
            )
            dataManager.budgets[existingIndex] = updatedBudget
        } else {
            // Create new budget for this specific month only
            let newBudget = Budget(
                amount: amount,
                period: .monthly,
                month: month,
                year: year,
                dateCreated: Date()
            )
            dataManager.budgets.append(newBudget)
        }

        dataManager.saveData()
        isPresented = false
    }
}

// MARK: - Preview
#if DEBUG
struct EditMonthBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.setBudget(1000, period: .monthly)

        return EditMonthBudgetView(
            dataManager: dataManager,
            selectedMonth: Date(),
            isPresented: .constant(true)
        )
        .previewDisplayName("Edit Month Budget")
    }
}
#endif
