import SwiftUI

// MARK: - Transaction Detail View - View individual transaction details
struct TransactionDetailView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    let expense: Expense
    let allExpenses: [Expense]? // Optional list of all expenses in the context
    @Binding var isPresented: Bool
    let parentCategory: CustomCategory? // Track if we came from a category view
    let parentRecurringId: UUID? // Track if we came from a recurring expense view
    @Environment(\.presentationMode) var presentationMode

    @State private var currentExpense: Expense

    @State private var showElements = false
    @State private var isEditing = false
    @State private var editedAmount: String = ""
    @State private var editedNote: String = ""
    @State private var editedCategory: CustomCategory?
    @State private var editedSubcategory: Subcategory?
    @State private var editedDate: Date = Date()
    @State private var showingCustomNumberPad = false
    @State private var showingCategoryPicker = false
    @State private var showingSubcategoryPicker = false
    @State private var showingDatePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteMessage = ""
    @State private var selectedIndex: Int = 0
    @State private var slideDirection: SlideDirection = .none
    @State private var showingUnsavedChangesAlert = false
    @State private var refreshID = UUID()
    @State private var pendingNavigationAction: (() -> Void)?
    @State private var categoryToShow: CustomCategory? = nil
    @State private var isInitializing = false // Track if we're in initial setup
    @State private var showingRecurringEditAlert = false
    @State private var pendingCategory: CustomCategory? = nil
    @State private var pendingSubcategory: Subcategory? = nil
    @State private var recurringEditType: RecurringEditType = .category
    @State private var showingRecurringDetail = false
    @State private var recurringToShow: RecurringExpense? = nil

    enum RecurringEditType {
        case category, subcategory
    }

    enum SlideDirection {
        case none, left, right
    }

    var hasUnsavedChanges: Bool {
        guard isEditing else {
            print("DEBUG hasUnsavedChanges: isEditing is false, returning false")
            return false
        }

        // Check if any field has been edited
        let amountChanged = !editedAmount.isEmpty && Double(editedAmount) != currentExpense.amount
        let categoryChanged = editedCategory != nil && editedCategory?.id != currentExpense.categoryId
        let subcategoryChanged = editedSubcategory?.name != currentExpense.note
        let dateChanged = {
            let calendar = Calendar.current
            let editedDateStart = calendar.startOfDay(for: editedDate)
            let currentDateStart = calendar.startOfDay(for: currentExpense.date)
            return editedDateStart != currentDateStart
        }()

        print("DEBUG hasUnsavedChanges:")
        print("  - isEditing: \(isEditing)")
        print("  - editedAmount: '\(editedAmount)', currentExpense.amount: \(currentExpense.amount)")
        print("  - amountChanged: \(amountChanged)")
        print("  - editedCategory: \(editedCategory?.name ?? "nil"), currentExpense.categoryId: \(currentExpense.categoryId?.uuidString ?? "nil")")
        print("  - categoryChanged: \(categoryChanged)")
        print("  - editedSubcategory: '\(editedSubcategory?.name ?? "nil")', currentExpense.note: '\(currentExpense.note)'")
        print("  - subcategoryChanged: \(subcategoryChanged)")
        print("  - editedDate: \(editedDate), currentExpense.date: \(currentExpense.date)")
        print("  - dateChanged: \(dateChanged)")
        print("  - FINAL RESULT: \(amountChanged || categoryChanged || subcategoryChanged || dateChanged)")

        return amountChanged || categoryChanged || subcategoryChanged || dateChanged
    }

    // Initialize currentExpense
    init(dataManager: BudgetDataManager, expense: Expense, allExpenses: [Expense]? = nil, isPresented: Binding<Bool>, parentCategory: CustomCategory? = nil, parentRecurringId: UUID? = nil, startInEditMode: Bool = false) {
        print("DEBUG: TransactionDetailView init - startInEditMode: \(startInEditMode)")
        self.dataManager = dataManager
        self.expense = expense
        self.allExpenses = allExpenses
        self._isPresented = isPresented
        self.parentCategory = parentCategory
        self.parentRecurringId = parentRecurringId
        self._currentExpense = State(initialValue: expense)
        self._isEditing = State(initialValue: startInEditMode)
        print("DEBUG: TransactionDetailView init - _isEditing set to: \(startInEditMode)")

        // Set initial selected index
        if let expenses = allExpenses, let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            self._selectedIndex = State(initialValue: index)
        }
    }

    var category: CustomCategory? {
        if let categoryId = currentExpense.categoryId {
            return categoryManager.allCategories.first { $0.id == categoryId }
        }
        return nil
    }

    var isRecurring: Bool {
        return currentExpense.recurringExpenseId != nil
    }

    var recurringExpense: RecurringExpense? {
        if let recurringId = currentExpense.recurringExpenseId {
            return dataManager.recurringExpenses.first { $0.id == recurringId }
        }
        return nil
    }

    var deletedRecurringExpense: RecurringExpense? {
        if let recurringId = currentExpense.recurringExpenseId {
            let deleted = dataManager.deletedRecurringExpenses.first { $0.id == recurringId }
            print("🔍 Looking for deleted recurring: \(recurringId)")
            print("   Found in deleted list: \(deleted != nil)")
            print("   Total deleted recurring expenses: \(dataManager.deletedRecurringExpenses.count)")
            print("   IDs in deleted list:")
            for (index, recurring) in dataManager.deletedRecurringExpenses.enumerated() {
                print("     [\(index)] \(recurring.id) - \(recurring.note)")
            }
            return deleted
        }
        return nil
    }

    var isRecurringDeleted: Bool {
        // Has a recurring ID but the recurring expense doesn't exist in active list
        guard let recurringId = currentExpense.recurringExpenseId else {
            print("🔍 isRecurringDeleted: No recurringExpenseId")
            return false
        }

        // Check if it exists in active recurring expenses
        let existsInActive = dataManager.recurringExpenses.contains { $0.id == recurringId }
        print("🔍 isRecurringDeleted: recurringId = \(recurringId)")
        print("   Exists in active list: \(existsInActive)")
        print("   Total active recurring: \(dataManager.recurringExpenses.count)")

        // If it doesn't exist in active list, it's deleted (even if not in deleted list due to cleanup)
        return !existsInActive
    }

    var currentIndex: Int? {
        guard let expenses = allExpenses else { return nil }
        return expenses.firstIndex(where: { $0.id == currentExpense.id })
    }

    var canSwipeLeft: Bool {
        guard let index = currentIndex, let expenses = allExpenses else { return false }
        return index > 0
    }

    var canSwipeRight: Bool {
        guard let index = currentIndex, let expenses = allExpenses else { return false }
        return index < expenses.count - 1
    }

    var transactionContentView: some View {
        VStack(spacing: 25) {
            // === HEADER SECTION ===
            VStack(spacing: 20) {
                // Category icon - use editedCategory in edit mode, otherwise use current expense category
                if let displayCategory = isEditing ? editedCategory : category {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [displayCategory.color.opacity(0.3), displayCategory.color.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: displayCategory.color.opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: displayCategory.icon)
                            .font(.system(size: 45))
                            .foregroundColor(displayCategory.color)
                    }
                }

                // Amount display
                VStack(spacing: 8) {
                    Text("Amount")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)

                    if isEditing {
                        Button(action: {
                            showingCustomNumberPad = true
                        }) {
                            HStack(spacing: 4) {
                                Text(String.currencySymbol())
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.colSecondaryText)

                                Text(editedAmount.isEmpty ? "0.00" : editedAmount)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.colPrimaryText)

                                Image(systemName: "pencil")
                                    .font(.title3)
                                    .foregroundColor(.colAccent)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text(currentExpense.amount.formattedCurrency())
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
            .padding(.top, 30)

            // === DETAILS CARD ===
            VStack(alignment: .leading, spacing: 20) {
                // Category
                if isEditing {
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "tag.fill")
                                .font(.title3)
                                .foregroundColor(editedCategory?.color ?? .colSecondaryText)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Category")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)

                                Text(editedCategory?.name ?? "Select Category")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                            }

                            Spacer()

                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.colAccent)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onChange(of: editedCategory) { newCategory in
                        print("DEBUG onChange(editedCategory) fired - isInitializing: \(isInitializing)")
                        print("  - newCategory: \(newCategory?.name ?? "nil")")
                        print("  - BEFORE clear - editedSubcategory: \(editedSubcategory?.name ?? "nil")")
                        // Only reset subcategory if we're not initializing
                        if !isInitializing {
                            // Reset subcategory when category changes
                            editedSubcategory = nil
                            editedNote = ""
                            print("  - AFTER clear - editedSubcategory: \(editedSubcategory?.name ?? "nil")")
                        } else {
                            print("  - SKIPPED clear because isInitializing = true")
                        }
                    }
                } else {
                    if let cat = category {
                        Button(action: {
                            // Check if we're already in this category's view
                            if let parentCat = parentCategory, parentCat.id == cat.id {
                                // We came from this category's view, so just dismiss
                                isPresented = false
                            } else {
                                // Different category or no parent, show the category detail
                                categoryToShow = cat
                            }
                        }) {
                            DetailRow(
                                icon: "tag.fill",
                                title: "Category",
                                value: cat.name,
                                color: cat.color
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Divider()
                    .background(Color.colSecondaryText.opacity(0.2))

                // Subcategory
                if isEditing {
                    Button(action: {
                        showingSubcategoryPicker = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "tag")
                                .font(.title3)
                                .foregroundColor(editedCategory?.color ?? .colSecondaryText)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subcategory")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)

                                Text(editedSubcategory?.name ?? "None")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                            }

                            Spacer()

                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.colAccent)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    DetailRow(
                        icon: "tag",
                        title: "Subcategory",
                        value: currentExpense.note.isEmpty ? "None" : currentExpense.note,
                        color: category?.color ?? .colSecondaryText
                    )
                }

                Divider()
                    .background(Color.colSecondaryText.opacity(0.2))

                // Date
                if isEditing {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(.colAccent)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)

                                Text(editedDate.formatted(date: .long, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                            }

                            Spacer()

                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.colAccent)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    DetailRow(
                        icon: "calendar",
                        title: "Date",
                        value: currentExpense.date.formatted(date: .long, time: .omitted),
                        color: .colAccent
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)

            // === RECURRING INFO CARD ===
            if isRecurring, let recurring = recurringExpense {
                Button(action: {
                    // Check if we came from this recurring's view
                    if let parentId = parentRecurringId, parentId == recurring.id {
                        // We came from this recurring view, so just dismiss
                        isPresented = false
                    } else {
                        // Different recurring or no parent, show the recurring detail
                        recurringToShow = recurring
                        showingRecurringDetail = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 12) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.title2)
                                .foregroundColor(.colAccent)

                            Text("Recurring Expense")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)
                        }
                        .padding(.bottom, 5)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Frequency:")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)

                                Spacer()

                                Text(recurring.recurrenceType.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                            }

                            HStack {
                                Text("Next occurrence:")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)

                                Spacer()

                                if recurring.isActive {
                                    if let nextDate = recurring.nextOccurrenceAfter(date: Date()) {
                                        Text(nextDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colAccent)
                                    } else {
                                        Text("N/A")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                } else {
                                    Text("Paused")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colAccent.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.colAccent.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if isRecurringDeleted {
                // === DELETED RECURRING INFO CARD ===
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("Recurring Expense Deleted")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                    .padding(.bottom, 5)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("This expense's recurring schedule has been deleted.")
                            .font(.subheadline)
                            .foregroundColor(.colSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        // Show original frequency if available
                        if let deleted = deletedRecurringExpense {
                            HStack(spacing: 8) {
                                Text("Original frequency:")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)

                                Text(deleted.recurrenceType.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                            }
                        }
                    }

                    // Restore button - only show if we have the deleted recurring data
                    if deletedRecurringExpense != nil {
                        Button(action: undeleteRecurringExpense) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.body)
                                Text("Restore Recurring Schedule")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.colOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // === ACTION BUTTONS ===
            if isEditing {
                // Save button
                Button(action: saveChanges) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Save Changes")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
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
                .padding(.horizontal)
            } else {
                // Delete button (only when not editing)
                Button(action: {
                    if isRecurring {
                        deleteMessage = "This expense is part of a recurring series. Only this single instance will be deleted."
                    } else {
                        deleteMessage = "Are you sure you want to delete this transaction?"
                    }
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                        Text("Delete Transaction")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.colOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            // Bottom spacing
            Color.clear.frame(height: 50)
        }
    }

    var body: some View {
        ZStack {
            Color.colBackground.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // === BACK BUTTON HEADER WITH TITLE ===
                ZStack {
                    // Centered title
                    HStack {
                        Spacer()
                        Text("Transaction Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                        Spacer()
                    }

                    // Back button on the left
                    HStack {
                        Button(action: {
                            if hasUnsavedChanges {
                                showingUnsavedChangesAlert = true
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.colBackButtonIcon)
                        }
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5), value: showElements)

                        Spacer()

                        // Edit button on the right (toggleable)
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isEditing {
                                    // Cancel editing - reset to original values
                                    isEditing = false
                                    editedAmount = ""
                                    editedNote = ""
                                    editedCategory = nil
                                    editedSubcategory = nil
                                    editedDate = Date()
                                } else {
                                    // Start editing
                                    isEditing = true
                                    editedAmount = String(format: "%.2f", currentExpense.amount)
                                    editedNote = currentExpense.note
                                    editedCategory = category
                                    editedDate = currentExpense.date

                                    // Find the subcategory based on the note
                                    if let cat = category, !currentExpense.note.isEmpty {
                                        let subcategories = categoryManager.getSubcategories(for: cat)
                                        editedSubcategory = subcategories.first { $0.name == currentExpense.note }

                                        // Debug: Log if subcategory not found
                                        if editedSubcategory == nil {
                                            print("⚠️ Subcategory '\(currentExpense.note)' not found in category '\(cat.name)'")
                                            print("   Available subcategories: \(subcategories.map { $0.name }.joined(separator: ", "))")
                                        }
                                    } else {
                                        editedSubcategory = nil
                                    }
                                }
                            }
                        }) {
                            ZStack {
                                if isEditing {
                                    Circle()
                                        .fill(Color.colAccent.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                }

                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.colAccent)
                            }
                        }
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5), value: showElements)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                .padding(.bottom, 5)

                // Use TabView for swipe navigation if allExpenses is provided
                if let expenses = allExpenses, expenses.count > 1 {
                    ZStack {
                        ScrollView {
                            transactionContentView
                        }
                        .id("\(currentExpense.id)-\(refreshID)")
                        .transition(.asymmetric(
                            insertion: .move(edge: slideDirection == .left ? .trailing : .leading),
                            removal: .move(edge: slideDirection == .left ? .leading : .trailing)
                        ))
                        .gesture(
                            DragGesture(minimumDistance: 30)
                                .onEnded { value in
                                    if value.translation.width > 50 {
                                        if selectedIndex > 0 {
                                            navigateToPrevious()
                                        } else {
                                            // At limit - warning haptic
                                            let notificationFeedback = UINotificationFeedbackGenerator()
                                            notificationFeedback.notificationOccurred(.warning)
                                        }
                                    } else if value.translation.width < -50 {
                                        if selectedIndex < expenses.count - 1 {
                                            navigateToNext()
                                        } else {
                                            // At limit - warning haptic
                                            let notificationFeedback = UINotificationFeedbackGenerator()
                                            notificationFeedback.notificationOccurred(.warning)
                                        }
                                    }
                                }
                        )

                        // Chevron overlay
                        VStack {
                            HStack(spacing: 20) {
                                // Left chevron
                                Button(action: {
                                    if selectedIndex > 0 {
                                        navigateToPrevious()
                                    } else {
                                        // At limit - warning haptic
                                        let notificationFeedback = UINotificationFeedbackGenerator()
                                        notificationFeedback.notificationOccurred(.warning)
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title2)
                                        .foregroundColor(selectedIndex > 0 ? .colAccent : .colSecondaryText.opacity(0.3))
                                        .padding(20)
                                }

                                Spacer()

                                // Right chevron
                                Button(action: {
                                    if selectedIndex < expenses.count - 1 {
                                        navigateToNext()
                                    } else {
                                        // At limit - warning haptic
                                        let notificationFeedback = UINotificationFeedbackGenerator()
                                        notificationFeedback.notificationOccurred(.warning)
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.title2)
                                        .foregroundColor(selectedIndex < expenses.count - 1 ? .colAccent : .colSecondaryText.opacity(0.3))
                                        .padding(20)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 50)

                            Spacer()
                        }
                        .allowsHitTesting(true)
                    }
                } else {
                    ScrollView {
                        transactionContentView
                    }
                }
            }

            // === CUSTOM NUMBER PAD OVERLAY ===
            if showingCustomNumberPad {
                CustomNumberPad(
                    text: $editedAmount,
                    isPresented: $showingCustomNumberPad,
                    onDismiss: {
                        showingCustomNumberPad = false
                    }
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            print("DEBUG: TransactionDetailView onAppear - isEditing: \(isEditing)")
            showElements = false
            withAnimation {
                showElements = true
            }

            // Initialize edit fields if starting in edit mode
            if isEditing {
                print("DEBUG: Initializing edit fields in onAppear")
                isInitializing = true // Prevent onChange from firing during init

                editedAmount = String(format: "%.2f", currentExpense.amount)
                editedNote = currentExpense.note
                editedCategory = category
                editedDate = currentExpense.date

                // Find the subcategory based on the note
                if let cat = category, !currentExpense.note.isEmpty {
                    editedSubcategory = categoryManager.getSubcategories(for: cat).first { $0.name == currentExpense.note }
                } else {
                    editedSubcategory = nil
                }

                print("DEBUG onAppear: Edit fields initialized")
                print("  - editedAmount: '\(editedAmount)'")
                print("  - editedCategory: \(editedCategory?.name ?? "nil")")
                print("  - editedSubcategory: \(editedSubcategory?.name ?? "nil")")
                print("  - editedDate: \(editedDate)")

                // Delay resetting isInitializing to ensure onChange doesn't fire during init
                DispatchQueue.main.async {
                    isInitializing = false // Done initializing
                    print("DEBUG: isInitializing set to false")
                }
            } else {
                print("DEBUG: NOT initializing edit fields because isEditing is false")
            }
        }
        .onChange(of: currentExpense.id) { _ in
            // Reset edit state when expense changes
            if isEditing {
                isEditing = false
                editedAmount = ""
                editedNote = ""
                editedCategory = nil
                editedSubcategory = nil
                editedDate = Date()
            }
        }
        .alert("Delete Transaction", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text(deleteMessage)
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Stay", role: .cancel) {
                pendingNavigationAction = nil
            }
            Button("Discard", role: .destructive) {
                // Reset edit state
                isEditing = false
                editedAmount = ""
                editedNote = ""
                editedCategory = nil
                editedSubcategory = nil
                editedDate = Date()

                // Execute pending action (either dismiss or navigate)
                if let action = pendingNavigationAction {
                    action()
                    pendingNavigationAction = nil
                } else {
                    // No pending action means it was the back button
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Recurring Expense", isPresented: $showingRecurringEditAlert) {
            Button("Cancel", role: .cancel) {
                pendingCategory = nil
                pendingSubcategory = nil
            }
            Button("Continue") {
                // Save changes to both this expense and the recurring template
                performSaveChanges(updateRecurringTemplate: true)
                pendingCategory = nil
                pendingSubcategory = nil
            }
        } message: {
            Text("This will update all past and future occurrences.")
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $editedCategory,
                isPresented: $showingCategoryPicker
            )
        }
        .sheet(isPresented: $showingSubcategoryPicker) {
            SubcategoryPickerSheet(
                categoryManager: categoryManager,
                selectedCategory: editedCategory,
                selectedSubcategory: $editedSubcategory,
                isPresented: $showingSubcategoryPicker
            )
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(
                selectedDate: $editedDate,
                isPresented: $showingDatePicker
            )
        }
        .fullScreenCover(item: $categoryToShow) { cat in
            CategoryDetailView(
                dataManager: dataManager,
                category: cat
            )
        }
        .fullScreenCover(item: $recurringToShow) { recurring in
            RecurringTransactionDetailView(
                recurringExpense: recurring,
                dataManager: dataManager
            )
        }
    }

    // MARK: - Category Picker Sheet
    struct CategoryPickerSheet: View {
        @StateObject private var categoryManager = CategoryManager()
        @Binding var selectedCategory: CustomCategory?
        @Binding var isPresented: Bool
        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            NavigationView {
                ZStack {
                    Color.colBackground.ignoresSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(categoryManager.allCategories) { category in
                                Button(action: {
                                    selectedCategory = category
                                    isPresented = false
                                }) {
                                    HStack(spacing: 15) {
                                        ZStack {
                                            Circle()
                                                .fill(category.color.opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: category.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(category.color)
                                        }

                                        Text(category.name)
                                            .font(.headline)
                                            .foregroundColor(.colPrimaryText)

                                        Spacer()

                                        if selectedCategory?.id == category.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.colAccent)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedCategory?.id == category.id ? Color.colAccent.opacity(0.1) : Color.colCardBackground)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.colAccent)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Select Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
        }
    }

    // MARK: - Subcategory Picker Sheet
    struct SubcategoryPickerSheet: View {
        @ObservedObject var categoryManager: CategoryManager
        let selectedCategory: CustomCategory?
        @Binding var selectedSubcategory: Subcategory?
        @Binding var isPresented: Bool
        @Environment(\.presentationMode) var presentationMode

        var subcategories: [Subcategory] {
            guard let category = selectedCategory else { return [] }
            return categoryManager.getSubcategories(for: category)
        }

        var body: some View {
            NavigationView {
                ZStack {
                    Color.colBackground.ignoresSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 12) {
                            // "None" option
                            Button(action: {
                                selectedSubcategory = nil
                                isPresented = false
                            }) {
                                HStack(spacing: 15) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.colSecondaryText.opacity(0.15))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "xmark")
                                            .font(.system(size: 18))
                                            .foregroundColor(.colSecondaryText)
                                    }

                                    Text("None")
                                        .font(.headline)
                                        .foregroundColor(.colPrimaryText)

                                    Spacer()

                                    if selectedSubcategory == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.colAccent)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSubcategory == nil ? Color.colAccent.opacity(0.1) : Color.colCardBackground)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Subcategory options
                            ForEach(subcategories) { subcategory in
                                Button(action: {
                                    selectedSubcategory = subcategory
                                    isPresented = false
                                }) {
                                    HStack(spacing: 15) {
                                        ZStack {
                                            Circle()
                                                .fill((selectedCategory?.color ?? .colSecondaryText).opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(selectedCategory?.color ?? .colSecondaryText)
                                        }

                                        Text(subcategory.name)
                                            .font(.headline)
                                            .foregroundColor(.colPrimaryText)

                                        Spacer()

                                        if selectedSubcategory?.id == subcategory.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.colAccent)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedSubcategory?.id == subcategory.id ? Color.colAccent.opacity(0.1) : Color.colCardBackground)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            if subcategories.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 40))
                                        .foregroundColor(.colSecondaryText.opacity(0.5))

                                    Text("No Subcategories")
                                        .font(.headline)
                                        .foregroundColor(.colPrimaryText)

                                    Text("This category has no subcategories")
                                        .font(.subheadline)
                                        .foregroundColor(.colSecondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.colAccent)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Select Subcategory")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
        }
    }

    // MARK: - Date Picker Sheet
    struct DatePickerSheet: View {
        @Binding var selectedDate: Date
        @Binding var isPresented: Bool
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            NavigationView {
                ZStack {
                    Color.colBackground.ignoresSafeArea(.all)

                    VStack(spacing: 20) {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .accentColor(.colAccent)
                            .colorScheme(colorScheme == .dark ? .dark : .light)
                            .padding()

                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Done")
                                .font(.headline)
                                .fontWeight(.semibold)
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
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.colAccent)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Select Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func navigateToPrevious() {
        // Check for unsaved changes
        if hasUnsavedChanges {
            pendingNavigationAction = { [self] in
                self.performNavigateToPrevious()
            }
            showingUnsavedChangesAlert = true
            return
        }

        performNavigateToPrevious()
    }

    private func performNavigateToPrevious() {
        guard let expenses = allExpenses else { return }

        if selectedIndex > 0 {
            // Success - navigate
            slideDirection = .right
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedIndex -= 1
                currentExpense = expenses[selectedIndex]
            }
            // Light haptic feedback for successful navigation
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            // At limit - can't go further
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }

    private func navigateToNext() {
        // Check for unsaved changes
        if hasUnsavedChanges {
            pendingNavigationAction = { [self] in
                self.performNavigateToNext()
            }
            showingUnsavedChangesAlert = true
            return
        }

        performNavigateToNext()
    }

    private func performNavigateToNext() {
        guard let expenses = allExpenses else { return }

        if selectedIndex < expenses.count - 1 {
            // Success - navigate
            slideDirection = .left
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedIndex += 1
                currentExpense = expenses[selectedIndex]
            }
            // Light haptic feedback for successful navigation
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else {
            // At limit - can't go further
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month], from: date, to: now)

        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }

    private func saveChanges() {
        print("🔵 saveChanges called")
        print("🔵 editedAmount: \(editedAmount)")
        print("🔵 editedCategory: \(editedCategory?.name ?? "nil")")

        guard let newAmount = Double(editedAmount), newAmount > 0 else {
            print("❌ Invalid amount")
            return
        }

        guard let updatedCategory = editedCategory else {
            print("❌ No category selected")
            return
        }

        // Check if this is a recurring expense and if category or subcategory changed
        if isRecurring {
            let categoryChanged = updatedCategory.id != category?.id
            let newNote = editedSubcategory?.name ?? ""
            let subcategoryChanged = newNote != currentExpense.note

            if categoryChanged || subcategoryChanged {
                // Show alert asking if user wants to update recurring template
                // Store both pending values
                pendingCategory = updatedCategory
                pendingSubcategory = editedSubcategory

                // Determine which one to highlight in the message
                if categoryChanged {
                    recurringEditType = .category
                } else {
                    recurringEditType = .subcategory
                }
                showingRecurringEditAlert = true
                return // Don't save yet, wait for user response
            }
        }

        // If not recurring or no category/subcategory changes, save directly
        performSaveChanges()
    }

    private func performSaveChanges(updateRecurringTemplate: Bool = false) {
        guard let newAmount = Double(editedAmount), newAmount > 0 else { return }
        guard let updatedCategory = editedCategory else { return }

        // Use subcategory name if selected, otherwise empty
        let updatedNote = editedSubcategory?.name ?? ""

        // Strip time from date - get start of day
        let calendar = Calendar.current
        let dateWithoutTime = calendar.startOfDay(for: editedDate)

        print("✅ Updating expense with amount: \(newAmount), category: \(updatedCategory.name), note: \(updatedNote)")

        // If updating recurring template, update BOTH category and subcategory
        if updateRecurringTemplate, let recurringId = currentExpense.recurringExpenseId {
            // Check if category changed
            if let pendingCat = pendingCategory, pendingCat.id != category?.id {
                dataManager.updateRecurringExpenseCategory(recurringId: recurringId, newCategory: pendingCat)
            }
            // Check if subcategory changed (always update note since it might have been cleared)
            let newNote = editedSubcategory?.name ?? ""
            if newNote != currentExpense.note {
                dataManager.updateRecurringExpenseNote(recurringId: recurringId, newNote: newNote)
            }
        }

        // Update the expense with new amount, note, category, and date
        dataManager.updateExpense(
            currentExpense,
            newAmount: newAmount,
            newNote: updatedNote,
            newCategory: updatedCategory,
            newDate: dateWithoutTime
        )

        print("✅ Expense updated successfully")

        // IMPORTANT: updateExpense creates a NEW expense with NEW ID, so we need to find it differently
        // Find the most recently updated expense with matching amount, category, and date
        if let updatedExpense = dataManager.expenses.first(where: {
            $0.amount == newAmount &&
            $0.categoryId == updatedCategory.id &&
            $0.note == updatedNote &&
            Calendar.current.isDate($0.date, inSameDayAs: dateWithoutTime)
        }) {
            currentExpense = updatedExpense
            print("🔄 Found and updated currentExpense.amount to: \(currentExpense.amount)")
        } else {
            print("⚠️ Could not find updated expense in dataManager")
        }

        // Exit edit mode - the view will now show the updated currentExpense data
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
        }
    }

    private func deleteTransaction() {
        dataManager.deleteExpense(currentExpense)
        presentationMode.wrappedValue.dismiss()
    }

    private func undeleteRecurringExpense() {
        guard let recurringId = currentExpense.recurringExpenseId else { return }

        // Restore the deleted recurring expense with all its original settings
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if let restoredRecurring = dataManager.restoreRecurringExpense(recurringId) {
                // The expense already has the correct recurringExpenseId, so no need to update it
                // Just refresh the view to show the blue recurring card
                refreshID = UUID()
            }
        }
    }

}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.colSecondaryText)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.colPrimaryText)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        let expense = Expense(amount: 45.50, note: "Groceries", date: Date(), category: .food)
        return TransactionDetailView(
            dataManager: dataManager,
            expense: expense,
            isPresented: .constant(true)
        )
        .previewDisplayName("Transaction Detail")
    }
}
#endif
