import SwiftUI

// MARK: - Calendar View
struct CalendarView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let selectedMonth: Date?
    @State private var currentMonth = Date()
    @State private var selectedDay: Int? = nil
    @State private var selectedExpenseForDetail: (expense: Expense, categoryExpenses: [Expense])? = nil
    @State private var selectedRecurringForDetail: RecurringExpense? = nil
    @State private var selectedCategoryForDetail: (category: CustomCategory, month: Date)? = nil
    @State private var selectedCategories: [CustomCategory] = []
    @State private var showingCategoryPicker = false
    @State private var filterRecurring: Bool? = nil // nil = all, true = recurring only, false = single-time only
    @State private var showFutureExpenses = false
    @StateObject private var categoryManager = CategoryManager()

    init(dataManager: BudgetDataManager, selectedMonth: Date? = nil, initialCategoryFilter: CustomCategory? = nil) {
        self.dataManager = dataManager
        self.selectedMonth = selectedMonth
        _currentMonth = State(initialValue: selectedMonth ?? Date())
        if let category = initialCategoryFilter {
            _selectedCategories = State(initialValue: [category])
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Calendar Card
                    VStack(spacing: 20) {
                    // Filter Pills and Category Filter
                    HStack(spacing: 12) {
                        // Filter Pills
                        HStack(spacing: 12) {
                            // Recurring Only
                            FilterPill(
                                title: "Recurring",
                                isSelected: filterRecurring == true,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if filterRecurring == true {
                                            filterRecurring = nil // Untoggle
                                        } else {
                                            filterRecurring = true
                                        }
                                    }
                                }
                            )

                            // Single-time Only
                            FilterPill(
                                title: "Single-time",
                                isSelected: filterRecurring == false,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if filterRecurring == false {
                                            filterRecurring = nil // Untoggle
                                        } else {
                                            filterRecurring = false
                                        }
                                    }
                                }
                            )
                        }

                        Spacer()

                        // Category Filter Button
                        Button(action: {
                            showingCategoryPicker = true
                        }) {
                            ZStack {
                                // Background circle when filters are active
                                if !selectedCategories.isEmpty {
                                    Circle()
                                        .fill(Color.colAccent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                }

                                Image(systemName: selectedCategories.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.colAccent)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    // Month selector with navigation arrows
                    HStack {
                        // Left arrow
                        Button(action: {
                            changeMonth(by: -1)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.currentTheme == .midnight ? Color.colCardBackground : Color(red: 0.98, green: 0.98, blue: 0.98))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.colPrimaryText)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Month display
                        Text(monthYearString)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Spacer()

                        // Right arrow
                        Button(action: {
                            changeMonth(by: 1)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.currentTheme == .midnight ? Color.colCardBackground : Color(red: 0.98, green: 0.98, blue: 0.98))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.colPrimaryText)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(isFutureMonth ? 0.4 : 1.0)
                    }
                    .padding(.horizontal, 20)

                    // Calendar grid
                    VStack(spacing: 0) {
                        // Weekday headers
                        HStack(spacing: 0) {
                            ForEach(weekdaySymbols, id: \.self) { day in
                                Text(day)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colSecondaryText)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 8)

                        // Calendar days grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 1) {
                            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, day in
                                if day == 0 {
                                    // Empty cell for days before month starts
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                } else {
                                    // Day cell
                                    GeometryReader { geo in
                                        let isSelected = selectedDay == day

                                        ZStack {
                                            // Background - either solid or split
                                            DayBackgroundView(
                                                day: day,
                                                selectedCategories: selectedCategories,
                                                dataManager: dataManager,
                                                themeManager: themeManager,
                                                filterExpenses: filterExpenses,
                                                hasFilteredOutExpenses: hasFilteredOutExpenses(day),
                                                filteredSpending: filteredSpendingForDay(day),
                                                dailyBudget: dailyBudgetForMonth(),
                                                getDateForDay: getDateForDay,
                                                cornerRadius: min(geo.size.width * 0.2, 8)
                                            )

                                            VStack(spacing: 2) {
                                                Text("\(day)")
                                                    .font(.system(size: min(geo.size.width * 0.35, 14), weight: .medium))
                                                    .foregroundColor(textColorForDay(day))

                                                // Future recurring expense indicators (multiple dots)
                                                let futureExpenses = futureRecurringExpensesForDay(day)
                                                if !futureExpenses.isEmpty {
                                                    let displayExpenses = Array(futureExpenses.prefix(6))
                                                    VStack(spacing: 2) {
                                                        // First row (up to 3 dots)
                                                        HStack(spacing: 2) {
                                                            ForEach(Array(displayExpenses.prefix(3).enumerated()), id: \.offset) { _, recurring in
                                                                Circle()
                                                                    .fill(recurring.effectiveCategory.color)
                                                                    .frame(width: 3, height: 3)
                                                            }
                                                        }

                                                        // Second row (up to 3 more dots)
                                                        if displayExpenses.count > 3 {
                                                            HStack(spacing: 2) {
                                                                ForEach(Array(displayExpenses.dropFirst(3).enumerated()), id: \.offset) { _, recurring in
                                                                    Circle()
                                                                        .fill(recurring.effectiveCategory.color)
                                                                        .frame(width: 3, height: 3)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .scaleEffect(isSelected ? 1.05 : 1.0)
                                        .opacity(isFutureDay(day) ? 0.3 : 1.0)
                                        .zIndex(isSelected ? 1 : 0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                                        .onTapGesture {
                                                // Haptic feedback
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()

                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    // Toggle: deselect if already selected, otherwise select
                                                    if selectedDay == day {
                                                        selectedDay = nil
                                                    } else {
                                                        selectedDay = day
                                                    }
                                                }
                                            }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                    .padding(.vertical, 20)
                    .id(currentMonth)
                    .transition(.opacity)
                }
                .padding(.bottom, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.currentTheme == .midnight ? Color.colCardBackground : Color(red: 0.96, green: 0.96, blue: 0.96))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss popup when tapping calendar background
                    if selectedDay != nil {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedDay = nil
                        }
                    }
                }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let horizontalDistance = value.translation.width
                            let verticalDistance = value.translation.height

                            // Only respond to primarily horizontal swipes (at least 3x more horizontal than vertical)
                            if abs(horizontalDistance) > 60 && abs(horizontalDistance) > abs(verticalDistance) * 3 {
                                if horizontalDistance > 0 {
                                    // Swipe right - go to previous month
                                    changeMonth(by: -1)
                                } else {
                                    // Swipe left - go to next month
                                    changeMonth(by: 1)
                                }
                            }
                        }
                )

                // Month Summary Card (only show when no day is selected)
                if selectedDay == nil {
                    MonthSummaryCard(
                        currentMonth: currentMonth,
                        dataManager: dataManager,
                        filterExpenses: filterExpenses
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                // Day Details Popup
                if let day = selectedDay {
                    let dayDate = getDateForDay(day)
                    let allDayExpenses = dataManager.expenses.filter { expense in
                        Calendar.current.isDate(expense.date, inSameDayAs: dayDate)
                    }.sorted(by: { $0.date > $1.date })

                    // Separate filtered and filtered-out expenses
                    let filteredExpenses = filterExpenses(allDayExpenses)
                    let filteredOutExpenses = allDayExpenses.filter { expense in
                        !filteredExpenses.contains(where: { $0.id == expense.id })
                    }

                    // Combine: filtered first, then filtered-out
                    let orderedExpenses = filteredExpenses + filteredOutExpenses

                    // Use total of ALL expenses (not just filtered)
                    let dayTotal = allDayExpenses.reduce(0) { $0 + $1.amount }

                    // Get future recurring expenses for this day
                    let allFutureRecurring = allFutureRecurringExpensesForDay(day)
                    let filteredFutureRecurring = futureRecurringExpensesForDay(day)
                    let filteredOutFutureRecurring = allFutureRecurring.filter { recurring in
                        !filteredFutureRecurring.contains(where: { $0.id == recurring.id })
                    }

                    DayDetailsInfoCard(
                        periodLabel: formatDate(dayDate),
                        amount: dayTotal,
                        expenses: orderedExpenses,
                        filteredExpenseIds: Set(filteredExpenses.map { $0.id }),
                        futureRecurringExpenses: filteredFutureRecurring + filteredOutFutureRecurring,
                        filteredRecurringIds: Set(filteredFutureRecurring.map { $0.id }),
                        isFutureDate: dayDate > Date(),
                        monthAverage: monthAverageForCurrentMonth(),
                        dailyBudget: dailyBudgetForMonth(),
                        averageLabel: "monthly average",
                        selectedExpenseForDetail: $selectedExpenseForDetail,
                        selectedRecurringForDetail: $selectedRecurringForDetail,
                        selectedCategoryForDetail: $selectedCategoryForDetail,
                        currentMonth: currentMonth,
                        dataManager: dataManager,
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                self.selectedDay = nil
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDay)
                }

                    // Bottom padding for safe scrolling
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 20)
            }
            .background(Color.colBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                    }
                }

                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.colPrimaryText)
                // for navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Schedule")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
        .onAppear {
            // Configure navigation bar appearance to match SpendingGraphView
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .fullScreenCover(item: Binding(
            get: { selectedExpenseForDetail?.expense },
            set: { if $0 == nil { selectedExpenseForDetail = nil } }
        )) { expense in
            let categoryExpenses = selectedExpenseForDetail?.categoryExpenses ?? []
            let _ = print("DEBUG: fullScreenCover triggered with allExpenses count: \(categoryExpenses.count)")
            TransactionDetailView(
                dataManager: dataManager,
                expense: expense,
                allExpenses: categoryExpenses,
                isPresented: Binding(
                    get: { selectedExpenseForDetail != nil },
                    set: { if !$0 { selectedExpenseForDetail = nil } }
                ),
                parentCategory: nil
            )
        }
        .fullScreenCover(item: $selectedRecurringForDetail) { recurring in
            RecurringTransactionDetailView(
                recurringExpense: recurring,
                dataManager: dataManager
            )
        }
        .fullScreenCover(item: Binding(
            get: { selectedCategoryForDetail?.category },
            set: { if $0 == nil { selectedCategoryForDetail = nil } }
        )) { category in
            CategoryDetailView(
                dataManager: dataManager,
                category: category,
                initialMonth: selectedCategoryForDetail?.month
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                categories: categoryManager.allCategories,
                selectedCategories: $selectedCategories,
                isPresented: $showingCategoryPicker
            )
        }
    }

    // MARK: - Helper Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()

        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        guard let currentYear = currentComponents.year,
              let currentMonthNum = currentComponents.month,
              let nowYear = nowComponents.year,
              let nowMonthNum = nowComponents.month else {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: currentMonth)
        }

        // Calculate if viewing is more than a year in past or any time in future past new year
        let isPastYear = (nowYear - currentYear > 1) ||
                        (nowYear - currentYear == 1 && nowMonthNum > currentMonthNum)
        let isFutureYear = currentYear > nowYear

        if isPastYear || isFutureYear {
            // More than a year ago OR future year - show month and year
            formatter.dateFormat = "MMMM yyyy"
        } else {
            // Within the last year - show month only
            formatter.dateFormat = "MMMM"
        }

        return formatter.string(from: currentMonth)
    }

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        return currentComponents.year == nowComponents.year &&
               currentComponents.month == nowComponents.month
    }

    private var isFutureMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        guard let currentYear = currentComponents.year,
              let currentMonthNum = currentComponents.month,
              let nowYear = nowComponents.year,
              let nowMonthNum = nowComponents.month else {
            return false
        }

        // Check if viewing month is in the future
        return currentYear > nowYear || (currentYear == nowYear && currentMonthNum >= nowMonthNum)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        return formatter.veryShortWeekdaySymbols
    }

    private var daysInMonth: [Int] {
        let calendar = Calendar.current

        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }

        // Get the number of days in the month
        guard let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return [] }
        let numberOfDays = range.count

        // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Create array with empty slots (0) before the first day
        var days: [Int] = Array(repeating: 0, count: firstWeekday - 1)

        // Add the actual days of the month
        days += Array(1...numberOfDays)

        return days
    }

    // MARK: - Helper Functions
    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the new month
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) else { return }

        // Check if new month is more than 1 year in the future or past
        if let oneYearFromNow = calendar.date(byAdding: .year, value: 1, to: now),
           let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) {
            let newMonthComponents = calendar.dateComponents([.year, .month], from: newMonth)
            let futureComponents = calendar.dateComponents([.year, .month], from: oneYearFromNow)
            let pastComponents = calendar.dateComponents([.year, .month], from: oneYearAgo)

            if let newYear = newMonthComponents.year,
               let newMonthNum = newMonthComponents.month,
               let maxYear = futureComponents.year,
               let maxMonth = futureComponents.month,
               let minYear = pastComponents.year,
               let minMonth = pastComponents.month {
                // Don't allow going beyond 1 year in the future
                if newYear > maxYear || (newYear == maxYear && newMonthNum > maxMonth) {
                    return
                }
                // Don't allow going beyond 1 year in the past
                if newYear < minYear || (newYear == minYear && newMonthNum < minMonth) {
                    return
                }
            }
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.easeInOut(duration: 0.3)) {
            // Dismiss popup when changing months
            selectedDay = nil
            currentMonth = newMonth
        }
    }

    private func getDateForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = day
        return calendar.date(from: dateComponents) ?? Date()
    }

    // Filter expenses based on selected filters
    private func filterExpenses(_ expenses: [Expense]) -> [Expense] {
        var filtered = expenses

        // Filter by recurring/single-time
        if let isRecurring = filterRecurring {
            filtered = filtered.filter { expense in
                let hasRecurringId = expense.recurringExpenseId != nil
                return hasRecurringId == isRecurring
            }
        }

        // Filter by selected categories
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { expense in
                selectedCategories.contains(where: { $0.id == expense.effectiveCategory.id })
            }
        }

        return filtered
    }

    // Get future recurring expenses scheduled for this day (filtered)
    private func futureRecurringExpensesForDay(_ day: Int) -> [RecurringExpense] {
        let date = getDateForDay(day)
        let calendar = Calendar.current
        let now = Date()

        // Only show future expenses for dates in the future
        guard date > now else { return [] }

        // Apply recurring filter (hide if single-time filter is active)
        if let isRecurring = filterRecurring, !isRecurring {
            return [] // Single-time filter active, hide all recurring
        }

        let allRecurring = dataManager.recurringExpenses.filter { recurring in
            guard recurring.isActive else { return false }

            // Check if this recurring expense should occur on this date
            return recurring.shouldProcessOn(date: date)
        }

        // Apply category filter
        if !selectedCategories.isEmpty {
            return allRecurring.filter { recurring in
                selectedCategories.contains(where: { $0.id == recurring.effectiveCategory.id })
            }
        }

        return allRecurring
    }

    // Get ALL future recurring expenses (unfiltered) for this day
    private func allFutureRecurringExpensesForDay(_ day: Int) -> [RecurringExpense] {
        let date = getDateForDay(day)
        let now = Date()

        guard date > now else { return [] }

        return dataManager.recurringExpenses.filter { recurring in
            guard recurring.isActive else { return false }
            return recurring.shouldProcessOn(date: date)
        }
    }

    // Check if day has future recurring expenses
    private func hasFutureRecurringExpenses(_ day: Int) -> Bool {
        return !futureRecurringExpensesForDay(day).isEmpty
    }

    // Get all spending for a day (unfiltered)
    private func totalSpendingForDay(_ day: Int) -> Double {
        let date = getDateForDay(day)
        let calendar = Calendar.current

        let dayExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: date)
        }

        return dayExpenses.reduce(0) { $0 + $1.amount }
    }

    // Get filtered spending for a day
    private func filteredSpendingForDay(_ day: Int) -> Double {
        let date = getDateForDay(day)
        let calendar = Calendar.current

        let dayExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: date)
        }

        let filteredExpenses = filterExpenses(dayExpenses)
        return filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    // Check if day has expenses that are filtered out
    private func hasFilteredOutExpenses(_ day: Int) -> Bool {
        let total = totalSpendingForDay(day)
        let filtered = filteredSpendingForDay(day)
        return total > 0 && filtered == 0
    }

    private func dailyBudgetForMonth() -> Double {
        guard let budget = dataManager.budget else { return 0 }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return 0 }
        guard let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else { return 0 }
        let daysInMonth = range.count

        // Calculate daily budget based on the budget period
        switch budget.period {
        case .daily:
            return budget.amount
        case .weekly:
            return budget.amount / 7.0
        case .monthly:
            return budget.amount / Double(daysInMonth)
        case .yearly:
            return budget.amount / 365.0
        }
    }

    private func monthAverageForCurrentMonth() -> Double {
        let calendar = Calendar.current
        let allMonthExpenses = dataManager.expenses.filter { expense in
            let expenseComponents = calendar.dateComponents([.year, .month], from: expense.date)
            let currentComponents = calendar.dateComponents([.year, .month], from: currentMonth)
            return expenseComponents.year == currentComponents.year &&
                   expenseComponents.month == currentComponents.month
        }
        let monthExpenses = filterExpenses(allMonthExpenses)

        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return 0
        }

        // Calculate number of days to use for average
        let daysInMonth = range.count
        let now = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        let daysToUse: Int
        if currentMonthComponents.year == nowComponents.year &&
           currentMonthComponents.month == nowComponents.month {
            // Current month - only count days that have passed
            let currentDay = calendar.component(.day, from: now)
            daysToUse = currentDay
        } else {
            // Past or future month - use all days in month
            daysToUse = daysInMonth
        }

        let monthTotal = monthExpenses.reduce(0) { $0 + $1.amount }
        return daysToUse > 0 ? monthTotal / Double(daysToUse) : 0
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func backgroundColorForDay(_ day: Int) -> Color {
        // Check if all expenses are filtered out
        if hasFilteredOutExpenses(day) {
            // Has expenses but all filtered out - grey
            return Color.gray.opacity(0.5)
        }

        let filteredSpending = filteredSpendingForDay(day)

        if filteredSpending == 0 {
            // No spending (or no filtered spending) - white/light gray
            return themeManager.currentTheme == .midnight ? Color.gray.opacity(0.2) : Color.white
        }

        // Check if filtering by category
        if !selectedCategories.isEmpty {
            // Get filtered expenses for this day
            let date = getDateForDay(day)
            let calendar = Calendar.current
            let dayExpenses = dataManager.expenses.filter { expense in
                calendar.isDate(expense.date, inSameDayAs: date)
            }
            let filteredDayExpenses = filterExpenses(dayExpenses)

            // Get unique categories from filtered expenses
            let categories = Set(filteredDayExpenses.map { $0.effectiveCategory })

            if categories.count == 1, let singleCategory = categories.first {
                // Single category - use category color
                return singleCategory.color.opacity(0.7)
            } else if categories.count > 1 {
                // Multiple categories - use green
                return Color.green.opacity(0.7)
            }
        }

        // No category filter - use budget-based coloring
        let dailyBudget = dailyBudgetForMonth()
        if filteredSpending > dailyBudget {
            // Over budget - red
            return Color.red.opacity(0.7)
        } else {
            // Under budget - green
            return Color.green.opacity(0.7)
        }
    }

    private func textColorForDay(_ day: Int) -> Color {
        // Check if all expenses are filtered out
        if hasFilteredOutExpenses(day) {
            // Has expenses but all filtered out - grey with primary text
            return .colPrimaryText
        }

        let filteredSpending = filteredSpendingForDay(day)

        if filteredSpending == 0 {
            // No spending - normal text color
            return .colPrimaryText
        } else {
            // Has spending - white text for better contrast on colored backgrounds
            return .white
        }
    }

    private func isFutureDay(_ day: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Get the actual date for this day
        let dayDate = getDateForDay(day)
        let dayStart = calendar.startOfDay(for: dayDate)

        // Simply compare: is this day after today?
        return dayStart > today
    }
}

// MARK: - Reusable Day/Period Details Info Component
struct DayDetailsInfoCard: View {
    let periodLabel: String
    let amount: Double
    let expenses: [Expense]
    let filteredExpenseIds: Set<UUID>
    let futureRecurringExpenses: [RecurringExpense]
    let filteredRecurringIds: Set<UUID>
    let isFutureDate: Bool
    let monthAverage: Double
    let dailyBudget: Double
    let averageLabel: String
    @Binding var selectedExpenseForDetail: (expense: Expense, categoryExpenses: [Expense])?
    @Binding var selectedRecurringForDetail: RecurringExpense?
    @Binding var selectedCategoryForDetail: (category: CustomCategory, month: Date)?
    let currentMonth: Date
    let dataManager: BudgetDataManager
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Period")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.colSecondaryText)

                    Text(periodLabel)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.colSecondaryText)
                }
            }

            // Only show amount and comparison sections for non-future dates
            if !isFutureDate {
                Divider()
                    .background(Color.colSecondaryText.opacity(0.3))

                // Amount and Comparison
                VStack(spacing: 12) {
                    // Main Amount
                    VStack(spacing: 4) {
                        Text("Amount Spent")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.colSecondaryText)

                        Text(amount.formattedCurrency())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(amount > 0 ? .colAccent : .colSecondaryText)
                    }

                    // Comparison with average
                    let percentageDiff = monthAverage > 0 ? ((amount - monthAverage) / monthAverage) * 100 : 0

                    HStack(spacing: 8) {
                        Image(systemName: percentageDiff >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(percentageDiff >= 0 ? .red : .green)
                            .font(.caption)

                        Text("\(String(format: "%.0f", abs(percentageDiff)))% \(percentageDiff >= 0 ? "above" : "below") \(averageLabel)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.colSecondaryText)

                        Text("(\(monthAverage.formattedCurrency())/day)")
                            .font(.caption2)
                            .foregroundColor(.colSecondaryText.opacity(0.8))
                    }

                    // Budget goal comparison
                    if dailyBudget > 0 {
                        let budgetPercentageDiff = dailyBudget > 0 ? ((amount - dailyBudget) / dailyBudget) * 100 : 0

                        HStack(spacing: 8) {
                            let isOnPar = abs(budgetPercentageDiff) <= 5

                            if isOnPar {
                                Image(systemName: "target")
                                    .foregroundColor(.colAccent)
                                    .font(.caption)
                            } else {
                                Image(systemName: budgetPercentageDiff >= 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(budgetPercentageDiff >= 0 ? .orange : .green)
                                    .font(.caption)
                            }

                            if isOnPar {
                                Text("On par with budget goal")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.colSecondaryText)
                            } else {
                                Text("\(String(format: "%.0f", abs(budgetPercentageDiff)))% \(budgetPercentageDiff >= 0 ? "above" : "under") budget goal")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.colSecondaryText)
                            }

                            Text("(\(dailyBudget.formattedCurrency())/day)")
                                .font(.caption2)
                                .foregroundColor(.colSecondaryText.opacity(0.8))
                        }
                    }
                }

                // Transaction Details Section
            if !expenses.isEmpty {
                Divider()
                    .background(Color.colSecondaryText.opacity(0.3))

                VStack(alignment: .leading, spacing: 12) {
                    // Section Header
                    HStack {
                        Text("Transactions")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Spacer()

                        Text("\(expenses.count) transaction\(expenses.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.colSecondaryText)
                    }

                    // Spending by Category
                    let categoryGroups = Dictionary(grouping: expenses) { $0.effectiveCategory }
                        .sorted { (group1, group2) in
                            // Check if categories have filtered expenses
                            let hasFiltered1 = group1.value.contains { filteredExpenseIds.contains($0.id) }
                            let hasFiltered2 = group2.value.contains { filteredExpenseIds.contains($0.id) }

                            // Filtered categories come first
                            if hasFiltered1 && !hasFiltered2 {
                                return true
                            } else if !hasFiltered1 && hasFiltered2 {
                                return false
                            }

                            // Within same filter status, sort by amount
                            let amount1 = group1.value.reduce(0) { $0 + $1.amount }
                            let amount2 = group2.value.reduce(0) { $0 + $1.amount }
                            return amount1 > amount2
                        }

                    VStack(spacing: 12) {
                        ForEach(Array(categoryGroups.enumerated()), id: \.offset) { categoryIndex, categoryGroup in
                            let category = categoryGroup.key
                            let categoryExpenses = categoryGroup.value.sorted { $0.date > $1.date }
                            let categoryAmount = categoryExpenses.reduce(0) { $0 + $1.amount }
                            let percentage = amount > 0 ? (categoryAmount / amount) * 100 : 0

                            // Check if any expense in this category is filtered in
                            let hasFilteredExpense = categoryExpenses.contains { filteredExpenseIds.contains($0.id) }

                            VStack(alignment: .leading, spacing: 8) {
                                // Category header
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                        .foregroundColor(category.color)
                                        .frame(width: 16)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.name)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)

                                        Text("\(String(format: "%.0f", percentage))% of spending")
                                            .font(.caption2)
                                            .foregroundColor(.colSecondaryText.opacity(0.8))
                                    }

                                    Spacer()

                                    Text(categoryAmount.formattedCurrency())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.colPrimaryText)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategoryForDetail = (category: category, month: currentMonth)
                                }

                                // Individual expenses under this category
                                VStack(spacing: 6) {
                                    ForEach(categoryExpenses, id: \.id) { expense in
                                        ExpenseDetailRow(expense: expense, categoryColor: category.color)
                                            .onTapGesture {
                                                print("DEBUG: Setting expense with \(categoryExpenses.count) category expenses")
                                                selectedExpenseForDetail = (expense: expense, categoryExpenses: categoryExpenses)
                                            }
                                    }
                                }
                            }
                            .opacity(hasFilteredExpense ? 1.0 : 0.4)

                            // Show divider between all categories except the last one
                            if categoryIndex < categoryGroups.count - 1 {
                                Divider()
                                    .background(Color.colSecondaryText.opacity(0.1))
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            } else {
                Divider()
                    .background(Color.colSecondaryText.opacity(0.3))

                HStack {
                    Image(systemName: "creditcard.circle")
                        .font(.title2)
                        .foregroundColor(.colSecondaryText.opacity(0.5))

                    Text("No transactions recorded")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            } // End of !isFutureDate condition

            // Future Recurring Expenses Section
            if !futureRecurringExpenses.isEmpty {
                Divider()
                    .background(Color.colSecondaryText.opacity(0.3))
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Scheduled Recurring Expenses")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.colSecondaryText)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ForEach(futureRecurringExpenses, id: \.id) { recurring in
                        let isFiltered = filteredRecurringIds.contains(recurring.id)

                        HStack(spacing: 12) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.colAccent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recurring.note.isEmpty ? "Recurring expense" : recurring.note)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.colPrimaryText)

                                HStack(spacing: 4) {
                                    Image(systemName: recurring.effectiveCategory.icon)
                                        .font(.system(size: 10))
                                        .foregroundColor(recurring.effectiveCategory.color)

                                    Text(recurring.effectiveCategory.name)
                                        .font(.caption2)
                                        .foregroundColor(.colSecondaryText)

                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.colSecondaryText)

                                    Text(recurring.recurrenceType.displayText)
                                        .font(.caption2)
                                        .foregroundColor(.colSecondaryText)
                                }
                            }

                            Spacer()

                            Text(recurring.amount.formattedCurrency())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.colAccent)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.colAccent.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .opacity(isFiltered ? 1.0 : 0.4)
                        .onTapGesture {
                            selectedRecurringForDetail = recurring
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Expense Detail Row
struct ExpenseDetailRow: View {
    let expense: Expense
    let categoryColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(categoryColor.opacity(0.3))
                .frame(width: 4, height: 4)
                .padding(.leading, 28)

            Text(expense.note.isEmpty ? "Uncategorized" : expense.note)
                .font(.caption2)
                .foregroundColor(.colSecondaryText)
                .lineLimit(1)

            if expense.recurringExpenseId != nil {
                Image(systemName: "repeat.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.colSecondaryText.opacity(0.6))
            }

            Spacer()

            Text(expense.amount.formattedCurrency())
                .font(.caption2)
                .foregroundColor(.colSecondaryText)
        }
    }
}

// MARK: - Day Background View (Solid or Split)
struct DayBackgroundView: View {
    let day: Int
    let selectedCategories: [CustomCategory]
    let dataManager: BudgetDataManager
    let themeManager: ThemeManager
    let filterExpenses: ([Expense]) -> [Expense]
    let hasFilteredOutExpenses: Bool
    let filteredSpending: Double
    let dailyBudget: Double
    let getDateForDay: (Int) -> Date
    let cornerRadius: CGFloat

    var body: some View {
        let colors = getColorsForDay()

        if colors.count == 0 {
            // No spending - white/light gray
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(themeManager.currentTheme == .midnight ? Color.gray.opacity(0.2) : Color.white)
        } else if colors.count == 1 {
            // Single color - solid background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(colors[0])
        } else {
            // Multiple colors - split vertically
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        Rectangle()
                            .fill(color)
                            .frame(width: geo.size.width / CGFloat(colors.count))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    private func getColorsForDay() -> [Color] {
        // Check if all expenses are filtered out
        if hasFilteredOutExpenses {
            return [Color.gray.opacity(0.5)]
        }

        if filteredSpending == 0 {
            return [] // No spending
        }

        // Check if filtering by category
        if !selectedCategories.isEmpty {
            // Get filtered expenses for this day
            let date = getDateForDay(day)
            let calendar = Calendar.current
            let dayExpenses = dataManager.expenses.filter { expense in
                calendar.isDate(expense.date, inSameDayAs: date)
            }
            let filteredDayExpenses = filterExpenses(dayExpenses)

            // Get unique categories from filtered expenses
            let categories = Array(Set(filteredDayExpenses.map { $0.effectiveCategory }))

            if categories.count == 1, let singleCategory = categories.first {
                // Single category - use category color
                return [singleCategory.color.opacity(0.7)]
            } else if categories.count > 1 {
                // Multiple categories - return colors for split view (max 4)
                let sortedCategories = categories.sorted { cat1, cat2 in
                    let amount1 = filteredDayExpenses.filter { $0.effectiveCategory.id == cat1.id }.reduce(0) { $0 + $1.amount }
                    let amount2 = filteredDayExpenses.filter { $0.effectiveCategory.id == cat2.id }.reduce(0) { $0 + $1.amount }
                    return amount1 > amount2
                }
                // Take top 4 categories by amount
                return sortedCategories.prefix(4).map { $0.color.opacity(0.7) }
            }
        }

        // No category filter - use budget-based coloring
        if filteredSpending > dailyBudget {
            return [Color.red.opacity(0.7)]
        } else {
            return [Color.green.opacity(0.7)]
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .colPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.colAccent : Color.colSecondaryText.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Month Summary Card Component
struct MonthSummaryCard: View {
    let currentMonth: Date
    let dataManager: BudgetDataManager
    let filterExpenses: ([Expense]) -> [Expense]
    @EnvironmentObject var themeManager: ThemeManager

    private var monthExpenses: [Expense] {
        let calendar = Calendar.current
        let allMonthExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: currentMonth, toGranularity: .month)
        }
        return filterExpenses(allMonthExpenses)
    }

    private var totalSpent: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var transactionCount: Int {
        monthExpenses.count
    }

    private var comparisonMonth: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        let isCurrentMonth = currentMonthComponents.year == nowComponents.year &&
                            currentMonthComponents.month == nowComponents.month

        if isCurrentMonth {
            // Compare to last month
            return calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        } else {
            // Compare to current month
            return now
        }
    }

    private var comparisonExpenses: [Expense] {
        let calendar = Calendar.current
        let allComparisonExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: comparisonMonth, toGranularity: .month)
        }
        return filterExpenses(allComparisonExpenses)
    }

    private var comparisonTotal: Double {
        comparisonExpenses.reduce(0) { $0 + $1.amount }
    }

    private var percentageChange: Double {
        if comparisonTotal > 0 {
            return ((totalSpent - comparisonTotal) / comparisonTotal) * 100
        } else if totalSpent > 0 {
            return 999 // Cap at 999% for display
        } else {
            return 0
        }
    }

    private var formattedPercentage: String {
        let absChange = abs(percentageChange)
        if absChange >= 999 {
            return "999+"
        } else {
            return String(format: "%.0f", absChange)
        }
    }

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let nowComponents = calendar.dateComponents([.year, .month], from: now)

        return currentMonthComponents.year == nowComponents.year &&
               currentMonthComponents.month == nowComponents.month
    }

    private var comparisonText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let comparisonMonthName = formatter.string(from: comparisonMonth)

        if isCurrentMonth {
            return "vs last month (\(comparisonMonthName))"
        } else {
            return "vs current month"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Total Spent
            VStack(alignment: .leading, spacing: 3) {
                Text("Total Spent")
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundColor(.colSecondaryText)

                Text(totalSpent.formattedCurrency())
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.colPrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 35)

            // Transaction Count
            VStack(alignment: .leading, spacing: 3) {
                Text("Transactions")
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundColor(.colSecondaryText)

                Text("\(transactionCount)")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.colPrimaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 35)

            // Comparison
            VStack(alignment: .leading, spacing: 3) {
                Text(comparisonText)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundColor(.colSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Image(systemName: percentageChange >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(percentageChange >= 0 ? .red : .green)

                    Text("\(formattedPercentage)%")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme == .midnight ? Color.colCardBackground : Color(red: 0.96, green: 0.96, blue: 0.96))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}
