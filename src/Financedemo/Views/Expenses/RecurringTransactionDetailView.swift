import SwiftUI

// MARK: - Recurring Transaction Detail View
struct RecurringTransactionDetailView: View {
    let initialRecurringExpense: RecurringExpense
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isInitializingEdit = false // Track if we're initializing edit mode
    @State private var currentRecurringExpense: RecurringExpense

    // Edit state
    @State private var editedAmount = ""
    @State private var editedCategory: CustomCategory?
    @State private var editedSubcategory: Subcategory?
    @State private var editedNote = ""
    @State private var editedRecurrenceType: RecurrenceType = .daily
    @State private var editedDayOfWeek = 1
    @State private var editedDayOfMonth = 1
    @State private var editedMonthOfYear = 1
    @State private var editedTime = Date()
    @State private var showingCustomNumberPad = false
    @State private var showingCategoryPicker = false
    @State private var showingSubcategoryPicker = false
    @State private var showingFrequencyPicker = false
    @State private var showingSchedulePicker = false
    @State private var expensesToDelete: Set<UUID> = []
    @State private var showingCategoryChangeAlert = false
    @State private var pendingAction: PendingAction?
    @State private var selectedExpense: Expense?
    @StateObject private var categoryManager = CategoryManager()
    @State private var categoryToShow: CustomCategory? = nil

    enum PendingAction {
        case saveAndDismiss  // Back button pressed
        case saveAndStay     // Checkmark pressed
    }

    init(recurringExpense: RecurringExpense, dataManager: BudgetDataManager) {
        self.initialRecurringExpense = recurringExpense
        self.dataManager = dataManager
        self._currentRecurringExpense = State(initialValue: recurringExpense)
    }

    var recurringExpense: RecurringExpense {
        return currentRecurringExpense
    }

    // Get past logged expenses from this recurring
    var pastLoggedExpenses: [Expense] {
        dataManager.expenses.filter { expense in
            expense.recurringExpenseId == recurringExpense.id
        }.sorted { $0.date > $1.date }
    }

    // Calculate total amount spent
    var totalSpent: Double {
        pastLoggedExpenses.reduce(0) { $0 + $1.amount }
    }

    // Calculate next occurrence date
    var nextOccurrence: Date? {
        recurringExpense.nextOccurrenceAfter(date: Date())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 25) {
                        // Header - Icon, Amount, Name
                        VStack(spacing: 15) {
                            Image(systemName: isEditing && editedCategory != nil ? editedCategory!.icon : recurringExpense.effectiveCategory.icon)
                                .font(.system(size: 60))
                                .foregroundColor(isEditing && editedCategory != nil ? editedCategory!.color : recurringExpense.effectiveCategory.color)

                            if isEditing {
                                // Editable Amount
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
                                Text(recurringExpense.amount.formattedCurrency())
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.colPrimaryText)
                            }

                            if !recurringExpense.note.isEmpty {
                                HStack(spacing: 6) {
                                    Text(recurringExpense.note)
                                        .font(.title3)
                                        .foregroundColor(.colSecondaryText)

                                    if isEditing {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)
                                    }
                                }
                            }

                            // Active/Paused Badge - Toggleable
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    toggleActiveStatus()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: recurringExpense.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                                        .foregroundColor(.colOnAccent)
                                    Text(recurringExpense.isActive ? "Active" : "Paused")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colOnAccent)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(recurringExpense.isActive ? Color.green : Color.orange)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: recurringExpense.isActive)
                        }
                        .padding(.top, 20)

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
                            } else {
                                Button(action: {
                                    categoryToShow = recurringExpense.effectiveCategory
                                }) {
                                    HStack(spacing: 15) {
                                        Image(systemName: "tag.fill")
                                            .font(.title3)
                                            .foregroundColor(recurringExpense.effectiveCategory.color)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Category")
                                                .font(.caption)
                                                .foregroundColor(.colSecondaryText)

                                            Text(recurringExpense.effectiveCategory.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.colPrimaryText)
                                        }

                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
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
                                HStack(spacing: 15) {
                                    Image(systemName: "tag")
                                        .font(.title3)
                                        .foregroundColor(recurringExpense.effectiveCategory.color)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Subcategory")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)

                                        Text(recurringExpense.note.isEmpty ? "None" : recurringExpense.note)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }

                                    Spacer()
                                }
                            }

                            Divider()
                                .background(Color.colSecondaryText.opacity(0.2))

                            // Frequency
                            if isEditing {
                                Button(action: {
                                    showingFrequencyPicker = true
                                }) {
                                    HStack(spacing: 15) {
                                        Image(systemName: editedRecurrenceType.icon)
                                            .font(.title3)
                                            .foregroundColor(.colAccent)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Frequency")
                                                .font(.caption)
                                                .foregroundColor(.colSecondaryText)

                                            Text(editedRecurrenceType.displayText)
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
                                HStack(spacing: 15) {
                                    Image(systemName: recurringExpense.recurrenceType.icon)
                                        .font(.title3)
                                        .foregroundColor(.colAccent)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Frequency")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)

                                        Text(recurringExpense.recurrenceType.displayText)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }

                                    Spacer()
                                }
                            }

                            Divider()
                                .background(Color.colSecondaryText.opacity(0.2))

                            // Schedule
                            if isEditing {
                                Button(action: {
                                    showingSchedulePicker = true
                                }) {
                                    HStack(spacing: 15) {
                                        Image(systemName: "calendar")
                                            .font(.title3)
                                            .foregroundColor(.colAccent)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Schedule")
                                                .font(.caption)
                                                .foregroundColor(.colSecondaryText)

                                            Text(formatEditedSchedule())
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
                                HStack(spacing: 15) {
                                    Image(systemName: "calendar")
                                        .font(.title3)
                                        .foregroundColor(.colAccent)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Schedule")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)

                                        Text(formatSchedule())
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }

                                    Spacer()
                                }
                            }

                            if let next = nextOccurrence {
                                Divider()
                                    .background(Color.colSecondaryText.opacity(0.2))
                                    .transition(.opacity)

                                // Next Occurrence
                                HStack(spacing: 15) {
                                    Image(systemName: "clock.fill")
                                        .font(.title3)
                                        .foregroundColor(.colAccent)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Next Occurrence")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)

                                        Text(formatDate(next))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }

                                    Spacer()
                                }
                                .transition(.opacity)
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
                        .animation(.easeInOut(duration: 0.3), value: nextOccurrence != nil)

                        // === STATS CARD ===
                        VStack(alignment: .leading, spacing: 20) {
                            // Total Spent
                            HStack(spacing: 15) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Spent")
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)

                                    Text(totalSpent.formattedCurrency())
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.colPrimaryText)
                                }

                                Spacer()
                            }

                            Divider()
                                .background(Color.colSecondaryText.opacity(0.2))

                            // Times Logged
                            HStack(spacing: 15) {
                                Image(systemName: "number.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Times Logged")
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)

                                    Text("\(pastLoggedExpenses.count)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.colPrimaryText)
                                }

                                Spacer()
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

                        // === PAST LOGGED EXPENSES ===
                        if !pastLoggedExpenses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("History")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                    .padding(.horizontal)

                                VStack(spacing: 12) {
                                    ForEach(pastLoggedExpenses) { expense in
                                        HStack(spacing: 12) {
                                            // Icon or minus button
                                            if isEditing {
                                                Button(action: {
                                                    withAnimation {
                                                        if expensesToDelete.contains(expense.id) {
                                                            expensesToDelete.remove(expense.id)
                                                        } else {
                                                            expensesToDelete.insert(expense.id)
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.red)
                                                }
                                            } else {
                                                Image(systemName: expense.effectiveCategory.icon)
                                                    .font(.title3)
                                                    .foregroundColor(expense.effectiveCategory.color)
                                                    .frame(width: 24, height: 24)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(expense.note.isEmpty ? "Uncategorized" : expense.note)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)

                                                HStack {
                                                    Text(formatDate(expense.date))
                                                        .font(.caption)
                                                        .foregroundColor(.colSecondaryText)

                                                    Text("•")
                                                        .font(.caption)
                                                        .foregroundColor(.colSecondaryText)

                                                    Text(expense.date.formatted(date: .omitted, time: .shortened))
                                                        .font(.caption)
                                                        .foregroundColor(.colSecondaryText)
                                                }
                                            }

                                            Spacer()

                                            Text(expense.amount.formattedCurrency())
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.colPrimaryText)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.colCardBackground)
                                                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                                        )
                                        .opacity(expensesToDelete.contains(expense.id) ? 0.5 : 1.0)
                                        .onTapGesture {
                                            if !isEditing {
                                                selectedExpense = expense
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Auto-save before dismissing
                        if isEditing {
                            // Check if category/subcategory changed and there are past expenses
                            if hasCategoryOrSubcategoryChanges() && !pastLoggedExpenses.isEmpty {
                                pendingAction = .saveAndDismiss
                                showingCategoryChangeAlert = true
                            } else {
                                saveChanges()
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Recurring Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if isEditing {
                                // Check if category/subcategory changed and there are past expenses
                                if hasCategoryOrSubcategoryChanges() && !pastLoggedExpenses.isEmpty {
                                    pendingAction = .saveAndStay
                                    showingCategoryChangeAlert = true
                                } else {
                                    // Save changes when exiting edit mode
                                    saveChanges()
                                    isEditing = false
                                }
                            } else {
                                // Start editing
                                isInitializingEdit = true // Prevent onChange from firing
                                isEditing = true
                                editedAmount = String(format: "%.2f", recurringExpense.amount)
                                editedCategory = recurringExpense.effectiveCategory
                                editedRecurrenceType = recurringExpense.recurrenceType

                                // Initialize schedule values
                                editedTime = recurringExpense.selectedTime ?? Date()
                                editedDayOfWeek = recurringExpense.selectedDayOfWeek ?? Calendar.current.component(.weekday, from: Date())
                                editedDayOfMonth = recurringExpense.selectedDayOfMonth ?? Calendar.current.component(.day, from: Date())
                                editedMonthOfYear = recurringExpense.selectedMonthOfYear ?? Calendar.current.component(.month, from: Date())

                                // Find the subcategory based on the note
                                if !recurringExpense.note.isEmpty {
                                    let subcategories = categoryManager.getSubcategories(for: recurringExpense.effectiveCategory)
                                    editedSubcategory = subcategories.first { $0.name == recurringExpense.note }

                                    // Debug: Log if subcategory not found
                                    if editedSubcategory == nil {
                                        print("⚠️ [RecurringDetail] Subcategory '\(recurringExpense.note)' not found in category '\(recurringExpense.effectiveCategory.name)'")
                                        print("   Available subcategories: \(subcategories.map { $0.name }.joined(separator: ", "))")
                                    } else {
                                        print("✅ [RecurringDetail] Found subcategory: '\(editedSubcategory!.name)'")
                                    }
                                } else {
                                    editedSubcategory = nil
                                }

                                // Done initializing - allow onChange to fire normally
                                DispatchQueue.main.async {
                                    isInitializingEdit = false
                                }
                            }
                        }
                    }) {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                    }
                }
            }
        }
        .onAppear {
            // Initialize edit values
            editedAmount = String(format: "%.2f", recurringExpense.amount)

            // Configure navigation bar appearance to match SpendingGraphView
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .overlay {
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
        .sheet(isPresented: $showingFrequencyPicker) {
            FrequencyPickerSheet(
                selectedFrequency: $editedRecurrenceType,
                isPresented: $showingFrequencyPicker
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSchedulePicker) {
            SchedulePickerSheet(
                recurrenceType: editedRecurrenceType,
                selectedTime: $editedTime,
                selectedDayOfWeek: $editedDayOfWeek,
                selectedDayOfMonth: $editedDayOfMonth,
                selectedMonthOfYear: $editedMonthOfYear,
                isPresented: $showingSchedulePicker
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: editedCategory) { newCategory in
            // Reset subcategory when category changes (but not during initialization)
            if !isInitializingEdit {
                editedSubcategory = nil
                print("🔄 [RecurringDetail] Category changed, clearing subcategory")
            }
        }
        .onChange(of: editedRecurrenceType) { newType in
            // Set default schedule values based on frequency
            let calendar = Calendar.current
            let now = Date()

            switch newType {
            case .daily:
                editedTime = now
            case .weekly:
                editedDayOfWeek = calendar.component(.weekday, from: now)
            case .monthly:
                editedDayOfMonth = calendar.component(.day, from: now)
            case .yearly:
                editedMonthOfYear = calendar.component(.month, from: now)
                editedDayOfMonth = calendar.component(.day, from: now)
            case .singleTime:
                break
            }
        }
        .alert("Update Past Expenses?", isPresented: $showingCategoryChangeAlert) {
            Button("Continue") {
                // Save changes
                saveChanges()

                // Handle post-save action
                if pendingAction == .saveAndDismiss {
                    dismiss()
                } else {
                    // Stay on screen, exit edit mode
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditing = false
                    }
                }
                pendingAction = nil
            }

            Button("Cancel", role: .cancel) {
                // Handle cancel based on pending action
                if pendingAction == .saveAndDismiss {
                    // Back button was pressed - dismiss without saving
                    dismiss()
                } else {
                    // Checkmark was pressed - stay on screen, untoggle edit mode
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditing = false
                    }
                }
                pendingAction = nil
            }
        } message: {
            Text(getCategoryChangeMessage())
        }
        .fullScreenCover(item: $selectedExpense) { expense in
            TransactionDetailView(
                dataManager: dataManager,
                expense: expense,
                allExpenses: pastLoggedExpenses,
                isPresented: Binding(
                    get: { selectedExpense != nil },
                    set: { if !$0 { selectedExpense = nil } }
                ),
                parentCategory: recurringExpense.effectiveCategory,
                parentRecurringId: recurringExpense.id
            )
        }
        .fullScreenCover(item: $categoryToShow) { cat in
            CategoryDetailView(
                dataManager: dataManager,
                category: cat
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

    // MARK: - Frequency Picker Sheet
    struct FrequencyPickerSheet: View {
        @Binding var selectedFrequency: RecurrenceType
        @Binding var isPresented: Bool
        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            NavigationView {
                ZStack {
                    Color.colBackground.ignoresSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(RecurrenceType.allCases.filter { $0 != .singleTime }, id: \.self) { frequency in
                                Button(action: {
                                    selectedFrequency = frequency
                                    isPresented = false
                                }) {
                                    HStack(spacing: 15) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.colAccent.opacity(0.15))
                                                .frame(width: 40, height: 40)

                                            Image(systemName: frequency.icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(.colAccent)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(frequency.displayText)
                                                .font(.headline)
                                                .foregroundColor(.colPrimaryText)

                                            Text(frequency.description)
                                                .font(.caption)
                                                .foregroundColor(.colSecondaryText)
                                        }

                                        Spacer()

                                        if selectedFrequency == frequency {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.colAccent)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedFrequency == frequency ? Color.colAccent.opacity(0.1) : Color.colCardBackground)
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
                        Text("Select Frequency")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
        }
    }

    // MARK: - Schedule Picker Sheet
    struct SchedulePickerSheet: View {
        let recurrenceType: RecurrenceType
        @Binding var selectedTime: Date
        @Binding var selectedDayOfWeek: Int
        @Binding var selectedDayOfMonth: Int
        @Binding var selectedMonthOfYear: Int
        @Binding var isPresented: Bool
        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            NavigationView {
                ZStack {
                    Color.colBackground.ignoresSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 20) {
                            switch recurrenceType {
                            case .daily:
                                // Time picker for daily
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Select Time")
                                        .font(.headline)
                                        .foregroundColor(.colPrimaryText)
                                        .padding(.horizontal)

                                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .colorScheme(.light)
                                }

                            case .weekly:
                                // Day of week picker
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Select Day of Week")
                                        .font(.headline)
                                        .foregroundColor(.colPrimaryText)
                                        .padding(.horizontal)

                                    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                                    ForEach(1...7, id: \.self) { day in
                                        Button(action: {
                                            selectedDayOfWeek = day
                                            isPresented = false
                                        }) {
                                            HStack {
                                                Text(dayNames[day - 1])
                                                    .font(.body)
                                                    .foregroundColor(.colPrimaryText)

                                                Spacer()

                                                if selectedDayOfWeek == day {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.colAccent)
                                                }
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedDayOfWeek == day ? Color.colAccent.opacity(0.1) : Color.colCardBackground)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal)
                                }

                            case .monthly:
                                // Day of month picker
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Select Day of Month")
                                        .font(.headline)
                                        .foregroundColor(.colPrimaryText)
                                        .padding(.horizontal)

                                    Picker("Day", selection: $selectedDayOfMonth) {
                                        ForEach(1...31, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 200)
                                    .colorScheme(.light)
                                }

                            case .yearly:
                                // Month and day picker
                                VStack(alignment: .leading, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Select Month")
                                            .font(.headline)
                                            .foregroundColor(.colPrimaryText)
                                            .padding(.horizontal)

                                        let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                                        Picker("Month", selection: $selectedMonthOfYear) {
                                            ForEach(1...12, id: \.self) { month in
                                                Text(monthNames[month - 1]).tag(month)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 150)
                                        .colorScheme(.light)
                                    }

                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Select Day")
                                            .font(.headline)
                                            .foregroundColor(.colPrimaryText)
                                            .padding(.horizontal)

                                        Picker("Day", selection: $selectedDayOfMonth) {
                                            ForEach(1...31, id: \.self) { day in
                                                Text("\(day)").tag(day)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 150)
                                        .colorScheme(.light)
                                    }
                                }

                            case .singleTime:
                                Text("Single-time expenses don't have a schedule")
                                    .foregroundColor(.colSecondaryText)
                                    .padding()
                            }
                        }
                        .padding(.vertical)
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
                        Text("Select Schedule")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                }
            }
        }
    }

    private func formatEditedSchedule() -> String {
        switch editedRecurrenceType {
        case .daily:
            return "Daily at \(formatTime(editedTime))"
        case .weekly:
            let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            return "Weekly on \(dayNames[editedDayOfWeek])"
        case .monthly:
            return "Monthly on day \(editedDayOfMonth)"
        case .yearly:
            let monthNames = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            return "Yearly on \(monthNames[editedMonthOfYear]) \(editedDayOfMonth)"
        case .singleTime:
            return "One-time"
        }
    }

    private func formatSchedule() -> String {
        switch recurringExpense.recurrenceType {
        case .daily:
            if let time = recurringExpense.selectedTime {
                return "Daily at \(formatTime(time))"
            }
            return "Daily"
        case .weekly:
            if let dayOfWeek = recurringExpense.selectedDayOfWeek {
                return "Every \(formatDayOfWeek(dayOfWeek))"
            }
            return "Weekly"
        case .monthly:
            if let dayOfMonth = recurringExpense.selectedDayOfMonth {
                return "Every \(formatDayOfMonth(dayOfMonth)) of the month"
            }
            return "Monthly"
        case .yearly:
            if let month = recurringExpense.selectedMonthOfYear {
                return "Every \(formatMonth(month))"
            }
            return "Yearly"
        case .singleTime:
            return "One-time"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatDayOfWeek(_ dayOfWeek: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek - 1]
    }

    private func formatDayOfMonth(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    private func formatMonth(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func hasCategoryOrSubcategoryChanges() -> Bool {
        let categoryChanged = editedCategory != nil && editedCategory?.id != recurringExpense.effectiveCategory.id
        let subcategoryChanged = (editedSubcategory?.name ?? "") != recurringExpense.note
        return categoryChanged || subcategoryChanged
    }

    private func getCategoryChangeMessage() -> String {
        let categoryChanged = editedCategory != nil && editedCategory?.id != recurringExpense.effectiveCategory.id
        let subcategoryChanged = (editedSubcategory?.name ?? "") != recurringExpense.note

        if categoryChanged && subcategoryChanged {
            return "This will update the category and subcategory of \(pastLoggedExpenses.count) past expense(s) to match this recurring expense."
        } else if categoryChanged {
            return "This will update the category of \(pastLoggedExpenses.count) past expense(s) to match this recurring expense."
        } else if subcategoryChanged {
            return "This will update the subcategory of \(pastLoggedExpenses.count) past expense(s) to match this recurring expense."
        }
        return ""
    }

    private func toggleActiveStatus() {
        guard let index = dataManager.recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) else {
            return
        }

        let existing = dataManager.recurringExpenses[index]

        // Create updated recurring expense with toggled isActive status
        let updatedRecurring = RecurringExpense(
            id: existing.id,
            amount: existing.amount,
            note: existing.note,
            category: existing.category,
            customCategory: existing.customCategory,
            recurrenceType: existing.recurrenceType,
            startDate: existing.startDate,
            createdDate: existing.createdDate,
            isActive: !existing.isActive,
            lastProcessedDate: existing.lastProcessedDate,
            selectedDate: existing.selectedDate,
            selectedTime: existing.selectedTime,
            selectedDayOfWeek: existing.selectedDayOfWeek,
            selectedDayOfMonth: existing.selectedDayOfMonth,
            selectedMonthOfYear: existing.selectedMonthOfYear
        )

        dataManager.recurringExpenses[index] = updatedRecurring
        currentRecurringExpense = updatedRecurring
        dataManager.saveData()
    }

    private func saveChanges() {
        guard let index = dataManager.recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) else {
            print("❌ DEBUG: Could not find recurring expense with id \(recurringExpense.id)")
            return
        }

        let existing = dataManager.recurringExpenses[index]

        // Get updated values or keep existing
        let newAmount = Double(editedAmount) ?? existing.amount
        let newCategory = editedCategory ?? existing.effectiveCategory
        let newNote = editedSubcategory?.name ?? ""
        let newRecurrenceType = editedRecurrenceType

        // Get schedule values based on recurrence type
        let newSelectedTime: Date? = (newRecurrenceType == .daily) ? editedTime : nil
        let newSelectedDayOfWeek: Int? = (newRecurrenceType == .weekly) ? editedDayOfWeek : nil
        let newSelectedDayOfMonth: Int? = (newRecurrenceType == .monthly || newRecurrenceType == .yearly) ? editedDayOfMonth : nil
        let newSelectedMonthOfYear: Int? = (newRecurrenceType == .yearly) ? editedMonthOfYear : nil

        print("🔍 DEBUG: Checking for changes...")
        print("  - Frequency changed: \(newRecurrenceType != existing.recurrenceType) (old: \(existing.recurrenceType.displayText), new: \(newRecurrenceType.displayText))")
        print("  - Time changed: \(newSelectedTime != existing.selectedTime)")
        print("  - Day of week changed: \(newSelectedDayOfWeek != existing.selectedDayOfWeek)")
        print("  - Day of month changed: \(newSelectedDayOfMonth != existing.selectedDayOfMonth)")
        print("  - Month of year changed: \(newSelectedMonthOfYear != existing.selectedMonthOfYear)")

        // Only update if something changed
        let hasChanges = newAmount != existing.amount ||
                        newCategory.id != existing.effectiveCategory.id ||
                        newNote != existing.note ||
                        newRecurrenceType != existing.recurrenceType ||
                        newSelectedTime != existing.selectedTime ||
                        newSelectedDayOfWeek != existing.selectedDayOfWeek ||
                        newSelectedDayOfMonth != existing.selectedDayOfMonth ||
                        newSelectedMonthOfYear != existing.selectedMonthOfYear ||
                        !expensesToDelete.isEmpty

        if hasChanges {
            print("✅ DEBUG: Changes detected, creating updated recurring expense...")

            // Reset lastProcessedDate if frequency or schedule changed
            let scheduleChanged = newRecurrenceType != existing.recurrenceType ||
                                newSelectedTime != existing.selectedTime ||
                                newSelectedDayOfWeek != existing.selectedDayOfWeek ||
                                newSelectedDayOfMonth != existing.selectedDayOfMonth ||
                                newSelectedMonthOfYear != existing.selectedMonthOfYear

            let newLastProcessedDate = scheduleChanged ? nil : existing.lastProcessedDate

            if scheduleChanged {
                print("⚠️ DEBUG: Schedule changed - resetting lastProcessedDate to recalculate next occurrence")
            }

            // Create updated recurring expense preserving the ID
            let updatedRecurring = RecurringExpense(
                id: existing.id,
                amount: newAmount,
                note: newNote,
                category: nil,
                customCategory: newCategory,
                recurrenceType: newRecurrenceType,
                startDate: existing.startDate,
                createdDate: existing.createdDate,
                isActive: existing.isActive,
                lastProcessedDate: newLastProcessedDate,
                selectedDate: existing.selectedDate,
                selectedTime: newSelectedTime,
                selectedDayOfWeek: newSelectedDayOfWeek,
                selectedDayOfMonth: newSelectedDayOfMonth,
                selectedMonthOfYear: newSelectedMonthOfYear
            )

            print("📋 DEBUG: Updated recurring expense details:")
            print("  - ID: \(updatedRecurring.id)")
            print("  - Frequency: \(updatedRecurring.recurrenceType.displayText)")
            print("  - Selected time: \(updatedRecurring.selectedTime?.description ?? "nil")")
            print("  - Selected day of week: \(updatedRecurring.selectedDayOfWeek?.description ?? "nil")")
            print("  - Selected day of month: \(updatedRecurring.selectedDayOfMonth?.description ?? "nil")")
            print("  - Selected month of year: \(updatedRecurring.selectedMonthOfYear?.description ?? "nil")")

            // Calculate next occurrence BEFORE and AFTER
            let oldNextOccurrence = existing.nextOccurrenceAfter(date: Date())
            let newNextOccurrence = updatedRecurring.nextOccurrenceAfter(date: Date())

            print("📅 DEBUG: Next occurrence comparison:")
            print("  - OLD next occurrence: \(oldNextOccurrence?.description ?? "nil")")
            print("  - NEW next occurrence: \(newNextOccurrence?.description ?? "nil")")

            dataManager.recurringExpenses[index] = updatedRecurring
            currentRecurringExpense = updatedRecurring

            print("💾 DEBUG: Updated dataManager and currentRecurringExpense")

            // Update category/subcategory of all past expenses if changed
            if newCategory.id != existing.effectiveCategory.id || newNote != existing.note {
                for pastExpense in pastLoggedExpenses {
                    dataManager.updateExpense(
                        pastExpense,
                        newAmount: pastExpense.amount,
                        newNote: newNote,
                        newCategory: newCategory,
                        newDate: pastExpense.date
                    )
                }
            }

            dataManager.saveData()
            print("✅ DEBUG: Data saved to disk")
        } else {
            print("ℹ️ DEBUG: No changes detected, skipping save")
        }

        // Delete selected expenses
        for expenseId in expensesToDelete {
            if let expense = dataManager.expenses.first(where: { $0.id == expenseId }) {
                dataManager.deleteExpense(expense)
                print("🗑️ DEBUG: Deleted expense \(expenseId)")
            }
        }
        expensesToDelete.removeAll()
    }
}
