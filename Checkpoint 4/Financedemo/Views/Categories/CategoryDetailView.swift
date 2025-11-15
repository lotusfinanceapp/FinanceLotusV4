import SwiftUI

// MARK: - Category Detail View - Detailed analytics for a specific category
struct CategoryDetailView: View {
    @ObservedObject var dataManager: BudgetDataManager
    let category: CustomCategory
    var initialMonth: Date? = nil // Optional initial month (for history)
    @State private var showElements = false
    @Environment(\.presentationMode) var presentationMode

    // Use current period expenses
    private var filteredExpenses: [Expense] {
        return dataManager.currentPeriodExpenses
    }

    // Computed properties for stats based on selected month
    private var transactionCount: Int {
        monthExpenses.count
    }

    private var proportionOfTotal: Double {
        let calendar = Calendar.current
        let allMonthExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: selectedMonth, toGranularity: .month)
        }
        let total = allMonthExpenses.reduce(0) { $0 + $1.amount }
        return total > 0 ? (monthTotal / total) * 100 : 0
    }

    private var changeFromLastPeriod: Double {
        let calendar = Calendar.current

        // Get last month
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return 0 }

        // Calculate last month total for this category
        let lastMonthTotal = dataManager.expenses
            .filter { expense in
                expense.effectiveCategory.id == category.id &&
                calendar.isDate(expense.date, equalTo: lastMonth, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }

        // Calculate percentage change
        if lastMonthTotal > 0 {
            return ((monthTotal - lastMonthTotal) / lastMonthTotal) * 100
        } else if monthTotal > 0 {
            return 100 // 100% increase from 0
        } else {
            return 0 // No change (both 0)
        }
    }

    @State private var selectedMonth = Date()
    @State private var showingMonthPicker = false
    @State private var isEditMode = false

    var body: some View {
        VStack(spacing: 0) {
            // === HEADER WITH BACK BUTTON ===
            ZStack {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.title3)
                            .foregroundColor(category.color)

                        Text(category.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                    Spacer()
                }

                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colBackButtonIcon)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5), value: showElements)

                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .padding(.bottom, 5)

            ScrollView {
                VStack(spacing: 20) {
                    // === MONTH SELECTOR ===
                    Button(action: {
                        showingMonthPicker.toggle()
                    }) {
                        HStack {
                            Text(monthYearString)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.colPrimaryText)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.colAccent)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.colCardBackground)
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    // === TOTAL SPENT CARD ===
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Spent")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)

                                Text(monthTotal.formattedCurrency())
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.colPrimaryText)
                            }

                            Spacer()

                            // Category icon
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.15))
                                    .frame(width: 64, height: 64)

                                Image(systemName: category.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(category.color)
                            }
                        }

                        // Quick stats row
                        HStack(spacing: 12) {
                            StatPill(
                                icon: changeFromLastPeriod >= 0 ? "arrow.up.right" : "arrow.down.right",
                                value: String(format: "%.0f%%", abs(changeFromLastPeriod)),
                                label: "vs last",
                                color: changeFromLastPeriod >= 0 ? .red : .green
                            )

                            StatPill(
                                icon: "chart.pie.fill",
                                value: String(format: "%.0f%%", proportionOfTotal),
                                label: "of total",
                                color: category.color
                            )

                            StatPill(
                                icon: "number",
                                value: "\(transactionCount)",
                                label: "transactions",
                                color: .colAccent
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal)

                    // === TRANSACTIONS BY SUBCATEGORY ===
                    TransactionsBySubcategorySection(
                        expenses: monthExpenses,
                        category: category,
                        dataManager: dataManager,
                        isEditMode: $isEditMode,
                        selectedMonth: selectedMonth
                    )

                    // Bottom padding
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 10)
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .onAppear {
            showElements = false
            // Set initial month if provided (from history)
            print("🔍 CategoryDetailView onAppear - initialMonth: \(initialMonth?.description ?? "nil")")
            if let month = initialMonth {
                print("🔍 Setting selectedMonth to: \(month)")
                selectedMonth = month
            } else {
                print("🔍 No initial month, using current date")
            }
            print("🔍 selectedMonth is now: \(selectedMonth)")
            withAnimation {
                showElements = true
            }
        }
        .onChange(of: selectedMonth) { _ in
            // Reset edit mode when month changes
            isEditMode = false
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerSheet(
                selectedMonth: $selectedMonth,
                monthOptions: monthOptions,
                isPresented: $showingMonthPicker
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }

    private var monthYearString: String {
        let calendar = Calendar.current
        let now = Date()

        // Check if it's current month
        if calendar.isDate(selectedMonth, equalTo: now, toGranularity: .month) {
            return "This Month"
        }

        // Check if it's last month
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
           calendar.isDate(selectedMonth, equalTo: lastMonth, toGranularity: .month) {
            return "Last Month"
        }

        // Otherwise show the month and year
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private var monthOptions: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []

        // Get last 12 months
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                dates.append(calendar.date(from: calendar.dateComponents([.year, .month], from: date))!)
            }
        }

        return dates
    }

    private var monthExpenses: [Expense] {
        let calendar = Calendar.current
        return dataManager.expenses.filter { expense in
            expense.effectiveCategory.id == category.id &&
            calendar.isDate(expense.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthTotal: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var categoryExpenses: [Expense] {
        filteredExpenses.filter { $0.effectiveCategory.id == category.id }
    }
}

// MARK: - Month Picker Sheet
struct MonthPickerSheet: View {
    @Binding var selectedMonth: Date
    let monthOptions: [Date]
    @Binding var isPresented: Bool

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    var body: some View {
        ZStack {
            // Background
            Color.colBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Select Month")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                    Spacer()
                }
                .padding(.vertical, 16)

                // Custom divider with theme color
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.2))
                    .frame(height: 1)

                // Picker wheel
                Picker("Month", selection: $selectedMonth) {
                    ForEach(monthOptions, id: \.self) { date in
                        Text(monthYearFormatter.string(from: date))
                            .foregroundColor(.colPrimaryText)
                            .tag(date)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 200)

                // Custom divider with theme color
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.2))
                    .frame(height: 1)

                // Done button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.colOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.colAccent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Identifiable String Wrapper
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

// MARK: - Transactions By Subcategory Section
struct TransactionsBySubcategorySection: View {
    let expenses: [Expense]
    let category: CustomCategory
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var isEditMode: Bool
    let selectedMonth: Date
    @State private var selectedExpense: Expense?
    @State private var deletingExpenseId: UUID?
    @Environment(\.presentationMode) var presentationMode

    private var isPastMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return !calendar.isDate(selectedMonth, equalTo: now, toGranularity: .month) &&
               selectedMonth < now
    }

    private var groupedBySubcategory: [(subcategory: String, expenses: [Expense])] {
        // Get all subcategories defined for this category
        var allSubcategories: Set<String> = Set(category.subcategories.map { $0.name })

        // Group existing expenses by subcategory
        let grouped = Dictionary(grouping: expenses) { expense in
            expense.note.isEmpty ? "Uncategorized" : expense.note
        }

        // Add subcategories from expenses that might not be in the predefined list
        for key in grouped.keys {
            allSubcategories.insert(key)
        }

        // Create array with all subcategories, including those with no expenses
        return allSubcategories.map { subcategoryName in
            let expensesForSubcategory = grouped[subcategoryName]?.sorted(by: { $0.date > $1.date }) ?? []
            return (subcategory: subcategoryName, expenses: expensesForSubcategory)
        }
        .sorted { first, second in
            let amount1 = first.expenses.reduce(0) { $0 + $1.amount }
            let amount2 = second.expenses.reduce(0) { $0 + $1.amount }

            // If amounts are equal, sort alphabetically by subcategory name
            if amount1 == amount2 {
                return first.subcategory < second.subcategory
            }
            // Otherwise, sort by amount (descending)
            return amount1 > amount2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Transactions header
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.colAccent)
                Text("Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.colPrimaryText)

                Spacer()

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    withAnimation {
                        isEditMode.toggle()
                    }
                }) {
                    Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isEditMode ? .green : .colAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Subcategory cards
            VStack(spacing: 16) {
                ForEach(groupedBySubcategory, id: \.subcategory) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Subcategory header
                        HStack {
                            Text(group.subcategory)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            Text(group.expenses.reduce(0) { $0 + $1.amount }.formattedCurrency())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(category.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // Horizontal scroll of transactions with Add button
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Existing transactions
                                ForEach(group.expenses, id: \.id) { expense in
                                    TransactionSquareCard(
                                        expense: expense,
                                        category: category,
                                        isEditMode: isEditMode,
                                        onDelete: {
                                            // Start deletion animation
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                deletingExpenseId = expense.id
                                            }

                                            // Delay actual deletion to allow animation
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                dataManager.deleteExpense(expense)

                                                // Reset animation state
                                                withAnimation {
                                                    deletingExpenseId = nil
                                                }
                                            }
                                        }
                                    )
                                    .opacity(deletingExpenseId == expense.id ? 0.0 : 1.0)
                                    .scaleEffect(deletingExpenseId == expense.id ? 0.5 : 1.0)
                                    .offset(y: deletingExpenseId == expense.id ? -20 : 0)
                                    .animation(.easeOut(duration: 0.3), value: deletingExpenseId)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                    .onTapGesture {
                                        if !isEditMode {
                                            selectedExpense = expense
                                        }
                                    }
                                }

                                // Add new button or "No transactions" message for current month
                                if !isPastMonth {
                                    Button(action: {
                                        isEditMode = false
                                        // Prepare data for log expense tab
                                        let subcategory = group.subcategory == "Uncategorized" ? nil : group.subcategory
                                        let userInfo: [String: Any] = [
                                            "category": category,
                                            "subcategory": subcategory as Any
                                        ]

                                        // Post notification first
                                        NotificationCenter.default.post(
                                            name: .switchToLogExpenseTab,
                                            object: nil,
                                            userInfo: userInfo
                                        )

                                        // Dismiss all presented views by dismissing to root
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootViewController = windowScene.windows.first?.rootViewController {
                                            rootViewController.dismiss(animated: true)
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.colAccent.opacity(0.15))
                                                    .frame(width: 32, height: 32)

                                                Image(systemName: "plus")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.colAccent)
                                            }

                                            Text("Add New")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.colPrimaryText)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.colCardBackground)
                                                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else if group.expenses.isEmpty {
                                    // Show "No transactions" message for past months with no expenses
                                    HStack(spacing: 10) {
                                        Text("No transactions")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colSecondaryText)
                                            .italic()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.colSecondaryText.opacity(0.05))
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colBackground)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .fullScreenCover(item: $selectedExpense) { expense in
            TransactionDetailView(
                dataManager: dataManager,
                expense: expense,
                allExpenses: expenses.sorted(by: { $0.date > $1.date }),
                isPresented: Binding(
                    get: { selectedExpense != nil },
                    set: { if !$0 { selectedExpense = nil } }
                ),
                parentCategory: category
            )
        }
    }
}

// MARK: - Transaction Square Card
struct TransactionSquareCard: View {
    let expense: Expense
    let category: CustomCategory
    let isEditMode: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Category icon on left with recurring badge OR delete button in edit mode
            ZStack {
                Circle()
                    .fill(isEditMode ? Color.red.opacity(0.15) : category.color.opacity(0.15))
                    .frame(width: 32, height: 32)

                if isEditMode {
                    Button(action: {
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.warning)
                        onDelete()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                } else {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(category.color)

                    // Recurring expense indicator badge
                    if expense.recurringExpenseId != nil {
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.colAccent)
                            .opacity(0.7)
                            .background(
                                Circle()
                                    .fill(Color.colCardBackground)
                                    .frame(width: 10, height: 10)
                            )
                            .offset(x: 11, y: -11)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                // Amount
                Text(expense.amount.formattedCurrency())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.colPrimaryText)

                // Abbreviated date
                Text(abbreviatedDate(expense.date))
                    .font(.system(size: 9))
                    .foregroundColor(.colSecondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    private func abbreviatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.colSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Subcategory Breakdown Section
struct SubcategoryBreakdownSection: View {
    let expenses: [Expense]
    let category: CustomCategory
    let showElements: Bool

    private var subcategoryData: [(name: String, amount: Double, percentage: Double)] {
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: expenses) { $0.note.isEmpty ? "Uncategorized" : $0.note }
        return grouped.map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }, percentage: ($0.value.reduce(0) { $0 + $1.amount } / total) * 100) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.colAccent)
                Text("Breakdown by Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.colPrimaryText)
            }

            if subcategoryData.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundColor(.colSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(subcategoryData, id: \.name) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.colPrimaryText)

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.colSecondaryText.opacity(0.1))
                                            .frame(height: 6)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(category.color)
                                            .frame(width: geo.size.width * (item.percentage / 100), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(item.amount.formattedCurrency())
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)

                                Text(String(format: "%.0f%%", item.percentage))
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .opacity(showElements ? 1.0 : 0.0)
        .offset(y: showElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showElements)
    }
}

// MARK: - Transaction List Section
struct TransactionListSection: View {
    let expenses: [Expense]
    let category: CustomCategory
    let showElements: Bool
    @ObservedObject var dataManager: BudgetDataManager
    @State private var selectedExpense: Expense?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.colAccent)
                Text("All Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.colPrimaryText)

                Spacer()

                Text("\(expenses.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.colSecondaryText)
            }

            if expenses.isEmpty {
                Text("No transactions in this period")
                    .font(.subheadline)
                    .foregroundColor(.colSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 10) {
                    ForEach(expenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                        Button(action: {
                            selectedExpense = expense
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: category.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(category.color)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(expense.note.isEmpty ? "Uncategorized" : expense.note)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)
                                        .lineLimit(1)

                                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)
                                }

                                Spacer()

                                Text(expense.amount.formattedCurrency())
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colBackground)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .opacity(showElements ? 1.0 : 0.0)
        .offset(y: showElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showElements)
        .fullScreenCover(item: $selectedExpense) { expense in
            TransactionDetailView(
                dataManager: dataManager,
                expense: expense,
                allExpenses: expenses.sorted(by: { $0.date > $1.date }),
                isPresented: Binding(
                    get: { selectedExpense != nil },
                    set: { if !$0 { selectedExpense = nil } }
                ),
                parentCategory: category
            )
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryDetailView(
            dataManager: BudgetDataManager(),
            category: CustomCategory(
                name: "Food",
                icon: "fork.knife",
                colorHex: "#FF6B6B"
            )
        )
        .previewDisplayName("Category Detail")
    }
}
#endif
