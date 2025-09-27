import SwiftUI

// MARK: - Log Spending Screen - ADD NEW EXPENSES
struct LogSpendingView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @State private var expenseAmount: String = ""  // User input for expense amount
    @State private var expenseNote: String = ""    // User input for expense description
    @State private var selectedCategory: CustomCategory? // Selected expense category
    @State private var showingAlert = false        // Controls alert display
    @State private var alertMessage = ""           // Alert message text
    @State private var showElements = false        // Controls entrance animations
    @State private var showingToast = false        // Controls toast notification
    @State private var toastMessage = ""           // Toast message text
    @State private var addedAmountForNotification = ""  // Amount for notification display
    @State private var showingCategoryManagement = false
    @State private var showingAddCategory = false
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var showingCategoryDetail = false
    @State private var selectedCategoryForDetail: CustomCategory?
    @State private var isAddingExpense = false             // Controls add button animation
    @State private var lastExpenseCount = 0               // Track expense count for animation
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // === TOP SPACING ===
                Color.clear.frame(height: 80) // Space for fixed logo
                
                // === HEADER SECTION ===
                VStack(spacing: 20) {
                    // Dollar sign icon (edit color with colDollarIcon)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.colDollarIcon)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.4), value: showElements)
                        
                    // Main heading
                    Text("Log an Expense")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                    
                    // Remaining budget display (edit color with colRemainingText)
                    if let budget = dataManager.budget {
                        Text("Remaining: \(dataManager.remainingAmount.formattedCurrency())")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.colRemainingText)
                    }
                }
                
            // === INPUT CARDS SECTION WITH STAGGERED ENTRANCE ===
            VStack(spacing: 25) {
                // === EXPENSE AMOUNT CARD ===
                BudgetInputCard(
                    title: "Amount Spent $",
                    placeholder: "0.00",
                    text: $expenseAmount,
                    keyboardType: .decimalPad
                )
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                
                // === EXPENSE CATEGORY SELECTION ===
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
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        // Display all categories from CategoryManager
                        ForEach(categoryManager.allCategories, id: \.id) { category in
                            Button(action: {
                                hideKeyboard()
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    selectedCategory = category
                                }
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Image(systemName: category.icon)
                                            .font(.title2)
                                            .foregroundColor(selectedCategory?.id == category.id ? .white : category.color)
                                        
                                        // Star indicator for starred categories
                                        if category.isStarred {
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 8))
                                                        .foregroundColor(.yellow)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    .frame(height: 28)
                                    
                                    Text(category.name.count > 14 ? String(category.name.prefix(14)) + "..." : category.name)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedCategory?.id == category.id ? .white : .colPrimaryText)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .frame(height: 16)
                                }
                                .frame(width: 95, height: 70)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCategory?.id == category.id ? category.color : category.color.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCategory?.id == category.id ? category.color : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                            ))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: categoryManager.allCategories.map { $0.isStarred })
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
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                
                // === EXPENSE DESCRIPTION CARD ===
                BudgetInputCard(
                    title: "Item Description",
                    placeholder: "e.g., Lunch, Movie ticket",
                    text: $expenseNote,
                    keyboardType: .default
                )
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
            }
            
            // === ADD EXPENSE BUTTON WITH SMOOTH ANIMATIONS ===
            Button(action: addExpenseAction) {
                addExpenseButtonContent
            }
            .disabled(expenseAmount.isEmpty || isAddingExpense)
            .opacity(showElements ? 1.0 : 0.0)
            .offset(y: showElements ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: showElements)
            
            
            // Add bottom padding for safe scrolling
            Color.clear.frame(height: 100)
            }
            .padding(.horizontal)
        }
        .background(Color.colBackground.ignoresSafeArea(.container, edges: .top))
        .onTapGesture {
            hideKeyboard()
        }
        .overlay(
            // Modern success notification
            VStack {
                if showingToast {
                    ModernNotificationView(
                        message: toastMessage,
                        amount: addedAmountForNotification
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
                        removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .top))
                    ))
                }
                
                Spacer()
            }
            .padding(.top, 100)
        )
        .onAppear {
            showElements = false
            // Reset state
            selectedExpenseForDetail = nil
            selectedCategoryForDetail = nil
            
            withAnimation {
                showElements = true
            }
        }
        .onDisappear {
            showElements = false
        }
        .alert("Invalid Amount", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
                .foregroundColor(.colPrimaryText)
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
        .sheet(item: $selectedExpenseForDetail, onDismiss: {
            selectedExpenseForDetail = nil
        }) { expense in
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                ExpenseDetailView(dataManager: dataManager, expense: expense)
            }
        }
        .fullScreenCover(isPresented: $showingCategoryDetail, onDismiss: {
            selectedCategoryForDetail = nil
        }) {
            CategoryDetailView(dataManager: dataManager, initialCategory: selectedCategoryForDetail)
        }
    }
    
    // === COMPUTED PROPERTIES FOR BUTTON ===
    private var addExpenseButtonContent: some View {
        HStack {
            if isAddingExpense {
                SwiftUI.ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Text(isAddingExpense ? "Adding..." : "Add Expense")
                .font(.headline)
                .foregroundColor(.white)
        }
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
        .scaleEffect(isAddingExpense ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isAddingExpense)
    }
    
    private func addExpenseAction() {
        hideKeyboard()
        withAnimation(.easeInOut(duration: 0.1)) {
            isAddingExpense = true
        }
        
        // Slight delay for visual feedback, then add expense
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            logExpense()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // === EXPENSE VALIDATION AND LOGGING ===
    private func logExpense() {
        // Validate amount is a positive number
        guard let amount = Double(expenseAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount greater than $0"
            showingAlert = true
            return
        }
        
        // Validate category is selected
        guard let category = selectedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            return
        }
        
        // Add expense to data manager with custom category
        dataManager.addExpense(amount, note: expenseNote, customCategory: category)
        
        // Store the amount for the notification before clearing
        let addedAmount = String(format: "%.2f", amount)
        
        // Clear input fields after successful entry
        withAnimation(.easeInOut(duration: 0.3)) {
            expenseAmount = ""
            expenseNote = ""
            selectedCategory = categoryManager.allCategories.first
            isAddingExpense = false // Reset button state
        }
        
        // Show success toast with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        toastMessage = "Expense Added Successfully!"
        addedAmountForNotification = addedAmount
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showingToast = true
        }
        
        // Auto-dismiss toast after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showingToast = false
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LogSpendingView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.budget = Budget(amount: 100.0, period: .weekly, dateCreated: Date())
        return LogSpendingView(dataManager: dataManager)
            .previewDisplayName("Log Spending Screen")
    }
}
#endif

// MARK: - Modern Notification View
struct ModernNotificationView: View {
    let message: String
    let amount: String
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        HStack(spacing: 16) {
            // Animated success icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.8),
                                Color.green
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .rotationEffect(.degrees(checkmarkRotation))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(message)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.colPrimaryText)
                
                HStack(spacing: 4) {
                    Text("$\(amount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("added to your expenses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.colSecondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            ZStack {
                // Main background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
                
                // Shimmer effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                    )
                
                // Border accent
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .padding(.horizontal, 20)
        .onAppear {
            // Animate checkmark
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                checkmarkScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                checkmarkRotation = 360
            }
            
            // Shimmer animation
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                shimmerOffset = 400
            }
        }
    }
}