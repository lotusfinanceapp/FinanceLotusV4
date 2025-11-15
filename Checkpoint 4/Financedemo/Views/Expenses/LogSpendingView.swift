import SwiftUI

// MARK: - Log Spending Screen - ADD NEW EXPENSES
struct LogSpendingView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var showingCustomNumberPad: Bool
    @Binding var expenseAmount: String
    @Binding var selectedCategory: CustomCategory? // Bind to parent to track unsaved state
    var initialSubcategoryName: String? = nil // Optional initial subcategory name
    var onExpenseAdded: (() -> Void)? = nil // Callback when expense is successfully added
    @StateObject private var categoryManager = CategoryManager()
    @State private var selectedSubcategory: Subcategory? // Selected subcategory
    @State private var showingAlert = false        // Controls alert display
    @State private var showingNoSubcategoryAlert = false // Alert for no subcategory
    @State private var showingUnsavedExpenseAlert = false // Alert for unsaved expense
    @State private var alertMessage = ""           // Alert message text
    @State private var pendingTabSelection: Int?   // Store pending tab change
    @State private var showElements = false        // Controls entrance animations
    @State private var showingToast = false        // Controls toast notification
    @State private var toastMessage = ""           // Toast message text (top line)
    @State private var toastSubtitle = ""          // Toast subtitle text (bottom line)
    @State private var addedAmountForNotification = ""  // Amount for notification display
    @State private var showingCategoryManagement = false
    @State private var showingAddCategory = false
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var showingCategoryDetail = false
    @State private var selectedCategoryForDetail: CustomCategory?
    @State private var showingAddSubcategory = false
    @State private var newSubcategoryName = ""
    @State private var showingSubcategoryManagement = false
    @State private var isAddingExpense = false             // Controls add button animation
    @State private var lastExpenseCount = 0               // Track expense count for animation
    @State private var showAllCategories = false          // Controls category expansion
    @FocusState private var descriptionFieldFocused: Bool // Focus state for description field

    // Computed properties for category filtering
    private var starredCategories: [CustomCategory] {
        categoryManager.allCategories.filter { $0.isStarred }
    }

    private var categoriesToShow: [CustomCategory] {
        var categories: [CustomCategory]

        if showAllCategories {
            categories = categoryManager.allCategories
        } else {
            let starred = starredCategories
            categories = starred.isEmpty ? Array(categoryManager.allCategories.prefix(5)) : starred
        }

        // Move selected category to the front if it exists
        if let selected = selectedCategory {
            // Remove from current position if it exists
            if let index = categories.firstIndex(where: { $0.id == selected.id }) {
                categories.remove(at: index)
            }
            // Insert at the front
            categories.insert(selected, at: 0)

            // If not showing all, limit to original count to maintain grid size
            if !showAllCategories {
                let starred = starredCategories
                let maxCount = starred.isEmpty ? 5 : starred.count
                categories = Array(categories.prefix(maxCount))
            }
        }

        return categories
    }

    private var hasMoreCategories: Bool {
        let starred = starredCategories
        if starred.isEmpty {
            return categoryManager.allCategories.count > 5
        } else {
            return categoryManager.allCategories.count > starred.count
        }
    }

    // Calculate responsive box dimensions based on screen width
    // Maintains 95/70 ratio (1.357) for consistent proportions
    private var categoryBoxDimensions: (width: CGFloat, height: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth < 390 {
            // Smaller phones: 86/62 (maintains 95/70 ratio)
            return (width: 86, height: 62)
        } else {
            // Standard and larger phones: original 95/70
            return (width: 95, height: 70)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                // === TOP SPACING ===
                Color.clear.frame(height: 80) // Space for fixed logo
                
                // === HEADER SECTION ===
                VStack(spacing: 20) {
                    // Main heading
                    Text("Log Spending")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.colSecondaryText)
                        .textCase(.uppercase)
                        .tracking(1)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4), value: showElements)
                }

                // === DIVIDER ===
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showElements)

            // === INPUT CARDS SECTION WITH STAGGERED ENTRANCE ===
            VStack(spacing: 25) {
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
                        // Display categories (starred first, or all if expanded)
                        ForEach(categoriesToShow, id: \.id) { category in
                            Button(action: {
                                hideKeyboard()
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    // Toggle selection - deselect if already selected
                                    if selectedCategory?.id == category.id {
                                        selectedCategory = nil
                                        selectedSubcategory = nil
                                        expenseAmount = "" // Reset amount when deselecting category
                                    } else {
                                        selectedCategory = category
                                        selectedSubcategory = nil // Clear subcategory when changing category
                                        expenseAmount = "" // Reset amount when changing category
                                    }
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
                                .frame(width: categoryBoxDimensions.width, height: categoryBoxDimensions.height)
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
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: categoriesToShow.map { $0.id })
                        }
                        
                        // Add new category button with + icon - only show when expanded
                        if showAllCategories {
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
                                .frame(width: categoryBoxDimensions.width, height: categoryBoxDimensions.height)
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

                        // Show expand/collapse button if there are more categories
                        if hasMoreCategories {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAllCategories.toggle()
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: showAllCategories ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.colAccent)
                                        .frame(height: 28)

                                    Text(showAllCategories ? "Show Less" : "Show More")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .frame(height: 16)
                                }
                                .frame(width: categoryBoxDimensions.width, height: categoryBoxDimensions.height)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.colSecondaryText.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.colSecondaryText.opacity(0.3), lineWidth: 1)
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

                // === SUBCATEGORY SELECTION ===
                // Only show if category is selected and has subcategories or can add new ones
                if let category = selectedCategory {
                    let allSubcategories = categoryManager.getSubcategories(for: category)

                    // Reorder subcategories to put selected one first
                    let subcategories: [Subcategory] = {
                        var subs = allSubcategories
                        if let selected = selectedSubcategory,
                           let index = subs.firstIndex(where: { $0.id == selected.id }) {
                            subs.remove(at: index)
                            subs.insert(selected, at: 0)
                        }
                        return subs
                    }()

                    VStack(alignment: .leading, spacing: 15) {
                        // Subcategory header
                        HStack {
                            Text("Subcategory")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            // Hamburger menu for subcategory management
                            Button(action: {
                                hideKeyboard()
                                showingSubcategoryManagement = true
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                                    .foregroundColor(.colAccent)
                            }
                        }

                        // Horizontal ScrollView for subcategories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Category-specific subcategories
                                ForEach(subcategories) { subcategory in
                                    Button(action: {
                                        hideKeyboard()
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            // Toggle selection - deselect if already selected
                                            if selectedSubcategory?.id == subcategory.id {
                                                selectedSubcategory = nil
                                                expenseAmount = "" // Reset amount when deselecting
                                            } else {
                                                selectedSubcategory = subcategory
                                                // Auto-fill amount if subcategory has a default amount
                                                if let defaultAmount = subcategory.defaultAmount {
                                                    // Format as whole number if no decimal places needed
                                                    if defaultAmount.truncatingRemainder(dividingBy: 1) == 0 {
                                                        expenseAmount = String(format: "%.0f", defaultAmount)
                                                    } else {
                                                        expenseAmount = String(format: "%.2f", defaultAmount)
                                                    }
                                                }
                                            }
                                        }
                                    }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "tag.fill")
                                            .font(.title2)
                                            .foregroundColor(selectedSubcategory?.id == subcategory.id ? .white : category.color)
                                            .frame(height: 28)

                                        Text(subcategory.name.count > 14 ? String(subcategory.name.prefix(14)) + "..." : subcategory.name)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedSubcategory?.id == subcategory.id ? .white : .colPrimaryText)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                            .frame(height: 16)
                                    }
                                    .frame(width: 95, height: 70)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedSubcategory?.id == subcategory.id ? category.color : category.color.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedSubcategory?.id == subcategory.id ? category.color : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                                ))
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: subcategories.map { $0.id })
                            }

                            // Add new subcategory button
                            Button(action: {
                                hideKeyboard()
                                showingAddSubcategory = true
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
                        .padding(.horizontal, 4)
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
                }

                // === EXPENSE AMOUNT CARD ===
                VStack(alignment: .leading, spacing: 15) {
                    // Card title
                    Text("Amount \(String.currencySymbol())")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)

                    // Amount display button
                    Button(action: {
                        hideKeyboard()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingCustomNumberPad = true
                        }
                    }) {
                        HStack {
                            Text(expenseAmount.isEmpty ? "0.00" : expenseAmount)
                                .font(.callout)
                                .foregroundColor(expenseAmount.isEmpty ? .colSecondaryText : .colPrimaryText)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.colInputBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.colAccent.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.colCardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .opacity(showElements ? 1.0 : 0.0)

            }
            
            // === ADD EXPENSE BUTTON WITH SMOOTH ANIMATIONS ===
            Button(action: addExpenseAction) {
                addExpenseButtonContent
            }
            .disabled(expenseAmount.isEmpty || isAddingExpense)
            .opacity(showElements ? 1.0 : 0.0)
            
            
            // Add bottom padding for safe scrolling
            Color.clear.frame(height: UIScreen.main.bounds.height < 700 ? 100 : 80)
            }
            .padding(.horizontal)
            }
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
                        amount: addedAmountForNotification,
                        subtitle: toastSubtitle
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

            // Check if we need to set initial subcategory (for when tab is already active)
            if let subcategoryName = initialSubcategoryName, let category = selectedCategory {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let subcategories = categoryManager.getSubcategories(for: category)
                    if let foundSubcategory = subcategories.first(where: { $0.name == subcategoryName }) {
                        selectedSubcategory = foundSubcategory

                        // Set default amount if subcategory has one
                        if let defaultAmount = foundSubcategory.defaultAmount, defaultAmount > 0 {
                            expenseAmount = String(format: "%.2f", defaultAmount)
                        }
                    }
                }
            }

            withAnimation {
                showElements = true
            }
        }
        .onChange(of: selectedCategory) { category in
            // When category is set, check if we need to set initial subcategory
            if let subcategoryName = initialSubcategoryName, let category = category {
                // Delay slightly to ensure categoryManager has loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let subcategories = categoryManager.getSubcategories(for: category)
                    if let foundSubcategory = subcategories.first(where: { $0.name == subcategoryName }) {
                        selectedSubcategory = foundSubcategory

                        // Set default amount if subcategory has one
                        if let defaultAmount = foundSubcategory.defaultAmount, defaultAmount > 0 {
                            expenseAmount = String(format: "%.2f", defaultAmount)
                        }
                    }
                }
            }
        }
        .onChange(of: initialSubcategoryName) { subcategoryName in
            // When initialSubcategoryName changes (from notification), set the subcategory
            if let subcategoryName = subcategoryName, let category = selectedCategory {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let subcategories = categoryManager.getSubcategories(for: category)
                    if let foundSubcategory = subcategories.first(where: { $0.name == subcategoryName }) {
                        selectedSubcategory = foundSubcategory

                        // Set default amount if subcategory has one
                        if let defaultAmount = foundSubcategory.defaultAmount, defaultAmount > 0 {
                            expenseAmount = String(format: "%.2f", defaultAmount)
                        }
                    }
                }
            }
        }
        .onDisappear {
            showElements = false
            // Reset to collapsed state when leaving the page
            showAllCategories = false
            // Reset number pad state
            showingCustomNumberPad = false
            expenseAmount = ""
            // Reset selected category when exiting
            selectedCategory = nil
        }
        .alert("Invalid Amount", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
                .foregroundColor(.colPrimaryText)
        }
        .alert("No Subcategory", isPresented: $showingNoSubcategoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                logExpenseWithoutSubcategory()
            }
        } message: {
            Text("Logging without a subcategory makes tracking harder. Continue?")
                .foregroundColor(.colPrimaryText)
        }
        .fullScreenCover(isPresented: $showingCategoryManagement) {
            CategoryManagementView(categoryManager: categoryManager, dataManager: dataManager)
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
            CircleExpansionView(dataManager: dataManager, initialCategory: selectedCategoryForDetail)
        }
        .sheet(isPresented: $showingAddSubcategory, onDismiss: {
            newSubcategoryName = ""
        }) {
            if let category = selectedCategory {
                AddSubcategorySheet(
                    category: category,
                    subcategoryName: $newSubcategoryName,
                    onAdd: { amount in
                        if !newSubcategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let defaultAmount = Double(amount)
                            categoryManager.addSubcategory(to: category, subcategoryName: newSubcategoryName.trimmingCharacters(in: .whitespaces), defaultAmount: defaultAmount)
                            newSubcategoryName = ""
                            showingAddSubcategory = false
                        }
                    },
                    isPresented: $showingAddSubcategory
                )
            }
        }
        .fullScreenCover(isPresented: $showingSubcategoryManagement) {
            if let category = selectedCategory {
                SubcategoryManagementView(
                    category: category,
                    categoryManager: categoryManager,
                    dataManager: dataManager,
                    isPresented: $showingSubcategoryManagement
                )
            }
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
                .foregroundColor(.colOnAccent)
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
            isAddingExpense = false
            return
        }

        // Validate category is selected
        guard let category = selectedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            isAddingExpense = false
            return
        }

        // Check if subcategory is selected
        guard let subcategory = selectedSubcategory else {
            showingNoSubcategoryAlert = true
            isAddingExpense = false
            return
        }

        // Mark subcategory as used (updates lastUsed timestamp)
        categoryManager.markSubcategoryAsUsed(subcategory, in: category)

        // Add single-time expense immediately (current time) using subcategory name as note
        dataManager.addExpense(amount, note: subcategory.name, customCategory: category, date: Date())

        // Store the formatted amount for the notification
        let addedAmount = amount.formattedCurrency()

        // Set toast message for today's expense
        toastMessage = "Logged for today."
        toastSubtitle = addedAmount

        // Clear input fields after successful entry
        withAnimation(.easeInOut(duration: 0.3)) {
            expenseAmount = ""
            selectedCategory = categoryManager.allCategories.first
            selectedSubcategory = nil
            isAddingExpense = false
        }

        // Show success toast with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

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

        // Call the callback if provided
        onExpenseAdded?()
    }

    // === LOG EXPENSE WITHOUT SUBCATEGORY ===
    private func logExpenseWithoutSubcategory() {
        guard let amount = Double(expenseAmount), amount > 0 else { return }
        guard let category = selectedCategory else { return }

        // Add expense with empty note (no subcategory)
        dataManager.addExpense(amount, note: "", customCategory: category, date: Date())

        // Store the formatted amount for the notification
        let addedAmount = amount.formattedCurrency()

        // Set toast message
        toastMessage = "Logged for today."
        toastSubtitle = addedAmount

        // Clear input fields
        withAnimation(.easeInOut(duration: 0.3)) {
            expenseAmount = ""
            selectedCategory = categoryManager.allCategories.first
            selectedSubcategory = nil
            isAddingExpense = false
        }

        // Show success toast with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

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

        // Call the callback if provided
        onExpenseAdded?()
    }
}
// MARK: - Preview
#if DEBUG
struct LogSpendingView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.setBudget(100.0, period: .weekly)
        return LogSpendingView(
            dataManager: dataManager,
            showingCustomNumberPad: .constant(false),
            expenseAmount: .constant(""),
            selectedCategory: .constant(nil)
        )
            .previewDisplayName("Log Spending Screen")
    }
}
#endif

// MARK: - Modern Notification View
struct ModernNotificationView: View {
    let message: String
    let amount: String
    let subtitle: String
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
                    .foregroundColor(.colOnAccent)
                    .scaleEffect(checkmarkScale)
                    .rotationEffect(.degrees(checkmarkRotation))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(message)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.colPrimaryText)

                Text(subtitle)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
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

    // Helper functions for scheduling
    private func dayName(for day: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[day - 1]
    }

    private func monthName(for month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }
}

// MARK: - Subcategory Management View
struct SubcategoryManagementView: View {
    let category: CustomCategory
    @ObservedObject var categoryManager: CategoryManager
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var isPresented: Bool
    @State private var subcategoryToDelete: Subcategory?
    @State private var showingDeleteConfirmation = false
    @State private var showingAddSubcategory = false
    @State private var newSubcategoryName = ""
    @State private var subcategoryToEdit: Subcategory?

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: category.icon)
                            .font(.system(size: 50))
                            .foregroundColor(category.color)

                        Text("Manage Subcategories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)

                        Text(category.name)
                            .font(.subheadline)
                            .foregroundColor(.colSecondaryText)
                    }
                    .padding(.top, 20)

                    if categoryManager.getSubcategories(for: category).isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "tag")
                                .font(.system(size: 60))
                                .foregroundColor(.colSecondaryText.opacity(0.5))

                            Text("No Subcategories")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Text("Add subcategories to track specific items")
                                .font(.subheadline)
                                .foregroundColor(.colSecondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(categoryManager.getSubcategories(for: category)) { subcategory in
                                    SubcategoryRow(
                                        subcategory: subcategory,
                                        categoryColor: category.color,
                                        onDelete: {
                                            subcategoryToDelete = subcategory
                                            showingDeleteConfirmation = true
                                        },
                                        onEdit: {
                                            subcategoryToEdit = subcategory
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.colBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.colAccent)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Manage Subcategories")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSubcategory = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.colAccent)
                        }
                    }
                }
            }
        }
        .alert("Delete Subcategory", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let subcategory = subcategoryToDelete {
                    categoryManager.deleteSubcategory(subcategory, from: category)
                }
            }
        } message: {
            Text("Are you sure you want to delete this subcategory?")
        }
        .sheet(isPresented: $showingAddSubcategory, onDismiss: {
            newSubcategoryName = ""
        }) {
            AddSubcategorySheet(
                category: category,
                subcategoryName: $newSubcategoryName,
                onAdd: { amount in
                    if !newSubcategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let defaultAmount = Double(amount)
                        categoryManager.addSubcategory(to: category, subcategoryName: newSubcategoryName.trimmingCharacters(in: .whitespaces), defaultAmount: defaultAmount)
                        newSubcategoryName = ""
                        showingAddSubcategory = false
                    }
                },
                isPresented: $showingAddSubcategory
            )
        }
        .sheet(item: $subcategoryToEdit) { subcategory in
            EditSubcategorySheet(
                category: category,
                subcategory: subcategory,
                categoryManager: categoryManager,
                dataManager: dataManager,
                isPresented: Binding(
                    get: { subcategoryToEdit != nil },
                    set: { if !$0 { subcategoryToEdit = nil } }
                )
            )
        }
    }
}

// MARK: - Subcategory Row
struct SubcategoryRow: View {
    let subcategory: Subcategory
    let categoryColor: Color
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .font(.title2)
                .foregroundColor(categoryColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(subcategory.name)
                    .font(.headline)
                    .foregroundColor(.colPrimaryText)

                if let defaultAmount = subcategory.defaultAmount {
                    Text("Default: \(defaultAmount.formattedCurrency())")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                } else {
                    Text("No default amount")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText.opacity(0.6))
                }
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundColor(.colAccent)
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Edit Subcategory Sheet
struct EditSubcategorySheet: View {
    let category: CustomCategory
    let subcategory: Subcategory
    @ObservedObject var categoryManager: CategoryManager
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var isPresented: Bool
    @State private var showElements = false
    @State private var subcategoryName: String = ""
    @State private var defaultAmount: String = ""
    @State private var showingCustomNumberPad = false

    var body: some View {
        VStack(spacing: 0) {
            // === HEADER SECTION WITH BACK BUTTON ===
            VStack(spacing: 20) {
                // Back button and title
                HStack {
                    Button(action: {
                        hideKeyboard()
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colBackButtonIcon)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5), value: showElements)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Title section
                VStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(category.color)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)

                    Text("Edit Subcategory")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    Text("Update \(category.name) subcategory details")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
            }
            .padding(.bottom, 30)

            // === FORM SECTION ===
            ScrollView {
                VStack(spacing: 25) {
                    // Form card
                    VStack(alignment: .leading, spacing: 25) {
                        // Subcategory Name Input
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Subcategory Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            TextField("", text: $subcategoryName)
                                .placeholder("e.g., Groceries, Gas", text: $subcategoryName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocorrectionDisabled()
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.words)
                                .font(.body)
                                .foregroundColor(.colInputText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.colInputBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.colIconPrimary.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                        }

                        // Default Amount Input (Optional)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Default Amount (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Button(action: {
                                hideKeyboard()
                                showingCustomNumberPad = true
                            }) {
                                HStack {
                                    Text(String.currencySymbol())
                                        .foregroundColor(.colSecondaryText)
                                    Text(defaultAmount.isEmpty ? "0.00" : defaultAmount)
                                        .foregroundColor(.colPrimaryText)
                                    Spacer()
                                }
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.colInputBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.colIconPrimary.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                            }

                            Text("Auto-fill this amount when selected")
                                .font(.caption)
                                .foregroundColor(.colSecondaryText)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 25)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 30)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)

                    // Save button at bottom
                    Button(action: {
                        hideKeyboard()
                        if !subcategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let newDefaultAmount = Double(defaultAmount)
                            categoryManager.updateSubcategory(subcategory, in: category, newName: subcategoryName.trimmingCharacters(in: .whitespaces), newDefaultAmount: newDefaultAmount, dataManager: dataManager)
                            isPresented = false
                        }
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
                    .disabled(subcategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(subcategoryName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showElements)

                    // Bottom spacing
                    Color.clear.frame(height: UIScreen.main.bounds.height < 700 ? 100 : 80)
                }
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            showElements = false
            // Pre-populate with existing values
            subcategoryName = subcategory.name
            if let existingAmount = subcategory.defaultAmount {
                defaultAmount = String(format: "%.2f", existingAmount)
            }
            withAnimation {
                showElements = true
            }
        }
        .overlay(
            Group {
                if showingCustomNumberPad {
                    CustomNumberPad(
                        text: $defaultAmount,
                        isPresented: $showingCustomNumberPad,
                        onDismiss: {}
                    )
                }
            }
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
