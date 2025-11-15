import SwiftUI

// MARK: - Expense Detail View - EDIT AND DELETE INDIVIDUAL EXPENSES
struct ExpenseDetailView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @Environment(\.dismiss) private var dismiss
    
    let expense: Expense
    @State private var editedAmount: String = ""
    @State private var editedNote: String = ""
    @State private var editedCategory: CustomCategory?
    @State private var editedDate: Date = Date()
    @State private var showElements = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingRecurringDeleteAlert = false
    @State private var showingCategoryManagement = false
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // === TOP SPACING ===
                        Color.clear.frame(height: 10)
                        
                        // === EXPENSE AMOUNT CARD ===
                        BudgetInputCard(
                            title: "Amount Spent \(String.currencySymbol())",
                            placeholder: "0.00",
                            text: $editedAmount,
                            keyboardType: .decimalPad
                        )
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: showElements)
                        
                        // === CATEGORY SELECTION CARD ===
                        VStack(alignment: .leading, spacing: 15) {
                            // Category header with 3-lines button
                            HStack {
                                Text("Category")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Spacer()
                                
                                // 3-lines toggle button for manage categories
                                Button(action: {
                                    hideKeyboard()
                                    showingCategoryManagement = true
                                }) {
                                    Image(systemName: "line.horizontal.3")
                                        .font(.title3)
                                        .foregroundColor(.colAccent)
                                }
                                .opacity(showElements ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.3), value: showElements)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                // Display all categories from CategoryManager
                                ForEach(categoryManager.allCategories, id: \.id) { category in
                                    Button(action: {
                                        hideKeyboard()
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            editedCategory = category
                                        }
                                    }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.title2)
                                                .foregroundColor(editedCategory?.id == category.id ? .white : category.color)
                                                .frame(height: 28)
                                            
                                            Text(category.name.count > 14 ? String(category.name.prefix(14)) + "..." : category.name)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(editedCategory?.id == category.id ? .white : .colPrimaryText)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(1)
                                                .frame(height: 16)
                                        }
                                        .frame(width: 95, height: 70)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(editedCategory?.id == category.id ? category.color : category.color.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(editedCategory?.id == category.id ? category.color : Color.clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Add new category button with + icon
                                Button(action: {
                                    hideKeyboard()
                                    showingAddCategory = true
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.colAccent)
                                            .frame(height: 28)
                                        
                                        Text("Add New")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colPrimaryText)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                            .frame(height: 16)
                                    }
                                    .frame(width: 100, height: 70)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.colAccent.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.colAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
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
                        .animation(.easeOut(duration: 0.3), value: showElements)
                        
                        // === EXPENSE NOTE CARD ===
                        BudgetInputCard(
                            title: "Item Description",
                            placeholder: "e.g., Lunch, Movie ticket",
                            text: $editedNote,
                            keyboardType: .default
                        )
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: showElements)
                        
                        // === DATE PICKER CARD ===
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Date")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)
                            
                            DatePicker("Expense Date", selection: $editedDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .accentColor(.colAccent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: showElements)
                        
                        // === SAVE BUTTON ===
                        Button(action: {
                            hideKeyboard()
                            saveExpense()
                        }) {
                            Text("Save Changes")
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
                        .disabled(editedAmount.isEmpty)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: showElements)
                        
                        // Add bottom padding for safe scrolling
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hideKeyboard()
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.colBackButtonIcon)
                            .padding(.bottom,5)
                            .padding(.top,5)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        hideKeyboard()
                        // Check if this expense is part of a recurring expense
                        if expense.recurringExpenseId != nil {
                            showingRecurringDeleteAlert = true
                        } else {
                            showingDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 21))
                            .foregroundColor(.red)
                            .padding(.bottom,5)
                            .padding(.top,5)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Expense")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.bottom,5)
                        .padding(.top,5)
                }
            }
        }
        .onAppear {
            // Configure navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            // Initialize with current expense values
            editedAmount = String(format: "%.2f", expense.amount)
            editedNote = expense.note
            editedCategory = expense.effectiveCategory
            editedDate = expense.date
            
            withAnimation {
                showElements = true
            }
        }
        .alert("Alert", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
        .alert("Recurring Expense", isPresented: $showingRecurringDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete This Only", role: .destructive) {
                deleteExpense()
            }
            Button("Delete Recurring", role: .destructive) {
                deleteRecurringExpense()
            }
        } message: {
            Text("This expense is part of a recurring expense. Would you like to delete just this expense or the entire recurring expense?")
        }
        .sheet(isPresented: $showingCategoryManagement) {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                CategoryManagementView(categoryManager: categoryManager, dataManager: dataManager)
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                CategoryEditView(
                    categoryManager: categoryManager,
                    existingCategory: nil,
                    isPresented: $showingAddCategory
                )
            }
        }
    }
    
    // === SAVE EXPENSE CHANGES ===
    private func saveExpense() {
        // Validate amount
        guard let amount = Double(editedAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount greater than $0"
            showingAlert = true
            return
        }
        
        // Validate category
        guard let category = editedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            return
        }
        
        // Update expense in data manager
        dataManager.updateExpense(expense, newAmount: amount, newNote: editedNote, newCategory: category, newDate: editedDate)
        
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // === DELETE EXPENSE ===
    private func deleteExpense() {
        dataManager.deleteExpense(expense)
        dismiss()
    }

    // === DELETE RECURRING EXPENSE ===
    private func deleteRecurringExpense() {
        // First delete the expense itself
        dataManager.deleteExpense(expense)

        // Then delete the recurring expense if it exists
        if let recurringId = expense.recurringExpenseId,
           let recurringExpense = dataManager.recurringExpenses.first(where: { $0.id == recurringId }) {
            dataManager.deleteRecurringExpense(recurringExpense)
        }

        dismiss()
    }
}

// MARK: - Preview
#if DEBUG
struct ExpenseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        let expense = Expense(amount: 25.0, note: "Lunch at the cafe", date: Date(), category: .food)
        return ExpenseDetailView(dataManager: dataManager, expense: expense)
            .previewDisplayName("Expense Detail Screen")
    }
}
#endif
