import Foundation
import SwiftUI

// MARK: - Data Manager - HANDLES ALL DATA OPERATIONS
class BudgetDataManager: ObservableObject {
    @Published var budgets: [Budget] = []    // All monthly budgets
    @Published var expenses: [Expense] = []  // List of all logged expenses
    @Published var recurringExpenses: [RecurringExpense] = [] // List of recurring expenses
    @Published var deletedRecurringExpenses: [RecurringExpense] = [] // List of deleted (soft-deleted) recurring expenses
    @Published var categoryManager = CategoryManager() // Category manager for dynamic category lookups

    // Computed property for current budget (for backward compatibility)
    var budget: Budget? {
        getBudget(for: Date())
    }

    // === STORAGE KEYS ===
    private let budgetsKey = "budgets"       // UserDefaults key for budgets storage
    private let expensesKey = "expenses"     // UserDefaults key for expenses storage
    private let recurringExpensesKey = "recurringExpenses" // UserDefaults key for recurring expenses
    private let deletedRecurringExpensesKey = "deletedRecurringExpenses" // UserDefaults key for deleted recurring expenses

    private var notificationManager: NotificationManager?

    init() {
        loadData() // Load saved data when app starts
        initializeBudgetEntries() // Create budgets for past 12 months and future months
    }

    // Initialize budget entries: create past 12 months and generate future ones as needed
    private func initializeBudgetEntries() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        print("\n=== Budget Initialization ===")

        // If budgets exist, create missing entries for past 12 months
        if !budgets.isEmpty {
            // Get reference budget (use current month's or the most recent one)
            guard let referenceBudget = getBudget(for: now) ?? budgets.last else { return }

            print("Creating budgets for past 12 months based on reference: $\(referenceBudget.amount)")

            // Create budgets for past 12 months (including current month)
            for i in 0..<12 {
                if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                    let month = calendar.component(.month, from: monthDate)
                    let year = calendar.component(.year, from: monthDate)

                    let budgetExists = budgets.contains(where: { $0.month == month && $0.year == year })
                    if !budgetExists {
                        let newBudget = Budget(
                            amount: referenceBudget.amount,
                            period: referenceBudget.period,
                            month: month,
                            year: year,
                            dateCreated: monthDate
                        )
                        budgets.append(newBudget)
                        print("✓ Created budget for \(month)/\(year): $\(referenceBudget.amount)")
                    }
                }
            }

            // Create budgets for next 12 months (future budgets use current month's budget)
            for i in 1...12 {
                if let monthDate = calendar.date(byAdding: .month, value: i, to: now) {
                    let month = calendar.component(.month, from: monthDate)
                    let year = calendar.component(.year, from: monthDate)

                    let budgetExists = budgets.contains(where: { $0.month == month && $0.year == year })
                    if !budgetExists {
                        let newBudget = Budget(
                            amount: referenceBudget.amount,
                            period: referenceBudget.period,
                            month: month,
                            year: year,
                            dateCreated: monthDate
                        )
                        budgets.append(newBudget)
                        print("✓ Created future budget for \(month)/\(year): $\(referenceBudget.amount)")
                    }
                }
            }

            saveData()
        }

        print("=== Budget Initialization Complete ===\n")
    }

    // Auto-generate future budgets when they don't exist
    private func ensureFutureBudgetExists(for date: Date) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let budgetExists = budgets.contains(where: { $0.month == month && $0.year == year })
        if !budgetExists {
            // Use current month's budget as reference for future months
            if let currentBudget = getBudget(for: Date()) {
                let newBudget = Budget(
                    amount: currentBudget.amount,
                    period: currentBudget.period,
                    month: month,
                    year: year,
                    dateCreated: date
                )
                budgets.append(newBudget)
                saveData()
            }
        }
    }

    func setNotificationManager(_ manager: NotificationManager) {
        self.notificationManager = manager
        manager.dataManager = self // Set bidirectional reference

        // Reschedule all notifications for active recurring expenses
        // This ensures notifications are restored after app reinstall or update
        rescheduleAllRecurringNotifications()

        // Process any pending recurring expenses
        processRecurringExpenses()
    }

    private func rescheduleAllRecurringNotifications() {
        guard let notificationManager = notificationManager else { return }

        // Reschedule notifications for all active recurring expenses
        for recurring in recurringExpenses where recurring.isActive {
            notificationManager.scheduleRecurringExpenseNotification(recurringExpense: recurring)
        }
    }

    func addRecurringExpense(_ recurringExpense: RecurringExpense) {
        recurringExpenses.append(recurringExpense)
        saveData()

        // Schedule notification for this recurring expense
        notificationManager?.scheduleRecurringExpenseNotification(recurringExpense: recurringExpense)
    }

    func deleteRecurringExpense(_ recurringExpense: RecurringExpense) {
        // Soft delete: Move to deleted list instead of removing completely
        if let index = recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) {
            let deletedExpense = recurringExpenses.remove(at: index)
            deletedRecurringExpenses.append(deletedExpense)
            print("🗑️ Soft deleted recurring expense: \(deletedExpense.note) (ID: \(deletedExpense.id))")
            print("   Now have \(deletedRecurringExpenses.count) deleted recurring expenses")
            saveData()

            // Cancel scheduled notifications for this recurring expense
            notificationManager?.cancelRecurringExpenseNotification(recurringExpenseId: recurringExpense.id)
        }
    }

    func toggleRecurringExpense(_ recurringExpense: RecurringExpense) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) {
            recurringExpenses[index].isActive.toggle()
            saveData()

            // Update notifications based on active state
            if recurringExpenses[index].isActive {
                // Re-schedule notification when activated
                notificationManager?.scheduleRecurringExpenseNotification(recurringExpense: recurringExpenses[index])
            } else {
                // Cancel notification when paused
                notificationManager?.cancelRecurringExpenseNotification(recurringExpenseId: recurringExpense.id)
            }
        }
    }

    func restoreRecurringExpense(_ recurringExpenseId: UUID) -> RecurringExpense? {
        // Find and restore a deleted recurring expense
        if let index = deletedRecurringExpenses.firstIndex(where: { $0.id == recurringExpenseId }) {
            let restoredExpense = deletedRecurringExpenses.remove(at: index)
            recurringExpenses.append(restoredExpense)
            saveData()

            // Re-schedule notification for restored recurring expense
            notificationManager?.scheduleRecurringExpenseNotification(recurringExpense: restoredExpense)

            return restoredExpense
        }
        return nil
    }

    func updateRecurringExpenseCategory(recurringId: UUID, newCategory: CustomCategory) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == recurringId }) {
            let existing = recurringExpenses[index]

            // Create a new RecurringExpense with updated category
            let updated = RecurringExpense(
                id: existing.id,
                amount: existing.amount,
                note: existing.note,
                category: existing.category,
                customCategory: newCategory,
                recurrenceType: existing.recurrenceType,
                startDate: existing.startDate,
                createdDate: existing.createdDate,
                isActive: existing.isActive,
                lastProcessedDate: existing.lastProcessedDate,
                selectedDate: existing.selectedDate,
                selectedTime: existing.selectedTime,
                selectedDayOfWeek: existing.selectedDayOfWeek,
                selectedDayOfMonth: existing.selectedDayOfMonth,
                selectedMonthOfYear: existing.selectedMonthOfYear
            )

            recurringExpenses[index] = updated

            // Update all existing expenses from this recurring template
            for (expenseIndex, expense) in expenses.enumerated() {
                if expense.recurringExpenseId == recurringId {
                    // Update each expense with the new category
                    updateExpense(
                        expense,
                        newAmount: expense.amount,
                        newNote: expense.note,
                        newCategory: newCategory,
                        newDate: expense.date,
                        newRecurringExpenseId: recurringId
                    )
                }
            }

            saveData()

            // Re-schedule notification with updated category
            notificationManager?.cancelRecurringExpenseNotification(recurringExpenseId: recurringId)
            notificationManager?.scheduleRecurringExpenseNotification(recurringExpense: updated)
        }
    }

    func updateRecurringExpenseNote(recurringId: UUID, newNote: String) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == recurringId }) {
            let existing = recurringExpenses[index]

            // Create a new RecurringExpense with updated note
            let updated = RecurringExpense(
                id: existing.id,
                amount: existing.amount,
                note: newNote,
                category: existing.category,
                customCategory: existing.customCategory,
                recurrenceType: existing.recurrenceType,
                startDate: existing.startDate,
                createdDate: existing.createdDate,
                isActive: existing.isActive,
                lastProcessedDate: existing.lastProcessedDate,
                selectedDate: existing.selectedDate,
                selectedTime: existing.selectedTime,
                selectedDayOfWeek: existing.selectedDayOfWeek,
                selectedDayOfMonth: existing.selectedDayOfMonth,
                selectedMonthOfYear: existing.selectedMonthOfYear
            )

            recurringExpenses[index] = updated

            // Update all existing expenses from this recurring template
            for (expenseIndex, expense) in expenses.enumerated() {
                if expense.recurringExpenseId == recurringId {
                    // Get current category for this expense
                    let currentCategory = categoryManager.allCategories.first { $0.id == expense.categoryId } ?? CustomCategory.fromExpenseCategory(.other)

                    // Update each expense with the new note
                    updateExpense(
                        expense,
                        newAmount: expense.amount,
                        newNote: newNote,
                        newCategory: currentCategory,
                        newDate: expense.date,
                        newRecurringExpenseId: recurringId
                    )
                }
            }

            saveData()

            // Re-schedule notification with updated note
            notificationManager?.cancelRecurringExpenseNotification(recurringExpenseId: recurringId)
            notificationManager?.scheduleRecurringExpenseNotification(recurringExpense: updated)
        }
    }

    func cleanupOrphanedDeletedRecurringExpenses() {
        // Remove deleted recurring expenses that have no associated transactions
        print("🧹 Cleanup: Before - \(deletedRecurringExpenses.count) deleted recurring expenses")

        let beforeCount = deletedRecurringExpenses.count
        deletedRecurringExpenses.removeAll { deletedRecurring in
            let hasExpenses = expenses.contains { $0.recurringExpenseId == deletedRecurring.id }
            print("  - Checking \(deletedRecurring.note): hasExpenses = \(hasExpenses)")
            return !hasExpenses // Remove if no expenses exist
        }

        print("🧹 Cleanup: After - \(deletedRecurringExpenses.count) deleted recurring expenses (removed \(beforeCount - deletedRecurringExpenses.count))")

        if beforeCount != deletedRecurringExpenses.count {
            saveData()
        }
    }

    func processRecurringExpenses() {
        let now = Date()
        let calendar = Calendar.current
        var hasChanges = false

        print("\n=== Processing Recurring Expenses (Catch-Up Mode) ===")
        print("Current time: \(now)")

        for i in 0..<recurringExpenses.count {
            let recurring = recurringExpenses[i]

            guard recurring.isActive else {
                print("Skipping inactive recurring expense: \(recurring.id)")
                continue
            }

            print("\n--- Checking recurring expense ---")
            print("ID: \(recurring.id)")
            print("Amount: $\(recurring.amount)")
            print("Category: \(recurring.effectiveCategory.name)")
            print("Type: \(recurring.recurrenceType.rawValue)")
            print("Start Date: \(recurring.startDate)")
            print("Last Processed: \(recurring.lastProcessedDate?.description ?? "Never")")

            // Find all missed occurrences since lastProcessedDate (or startDate if never processed)
            let missedOccurrences = getMissedOccurrences(for: recurring, upTo: now)

            if missedOccurrences.isEmpty {
                print("No missed occurrences")
                continue
            }

            print("Found \(missedOccurrences.count) missed occurrence(s)")

            // Log each missed occurrence at its scheduled time
            for scheduledDate in missedOccurrences {
                print("Logging expense for scheduled time: \(scheduledDate)")

                if let customCategory = recurring.customCategory {
                    addExpense(recurring.amount, note: recurring.note, customCategory: customCategory, date: scheduledDate, recurringExpenseId: recurring.id, sendNotification: false)
                } else if let category = recurring.category {
                    addExpense(recurring.amount, note: recurring.note, category: category, date: scheduledDate, recurringExpenseId: recurring.id, sendNotification: false)
                }

                hasChanges = true
            }

            // Update last processed date to the most recent occurrence
            if let lastOccurrence = missedOccurrences.last {
                recurringExpenses[i].lastProcessedDate = lastOccurrence
                print("Updated lastProcessedDate to: \(lastOccurrence)")
            }

            // If single-time, deactivate it after processing
            if recurring.recurrenceType == .singleTime {
                recurringExpenses[i].isActive = false
                print("Deactivated single-time expense")
            }
        }

        if hasChanges {
            saveData()
            objectWillChange.send()
            print("\n=== Recurring Expenses Processing Complete ===\n")
        } else {
            print("\n=== No recurring expenses to process ===\n")
        }
    }

    // Helper function to find all missed occurrences for a recurring expense
    private func getMissedOccurrences(for recurring: RecurringExpense, upTo currentDate: Date) -> [Date] {
        let calendar = Calendar.current
        var occurrences: [Date] = []

        // Determine the starting point for checking
        let checkStartDate: Date
        if let lastProcessed = recurring.lastProcessedDate {
            // Start checking from the day after last processed
            checkStartDate = calendar.date(byAdding: .day, value: 1, to: lastProcessed) ?? lastProcessed
        } else {
            // Never processed - start from the recurring expense's start date
            checkStartDate = recurring.startDate
        }

        // Don't process future dates
        guard checkStartDate <= currentDate else {
            return []
        }

        print("Checking for occurrences from \(checkStartDate) to \(currentDate)")

        switch recurring.recurrenceType {
        case .singleTime:
            // Single-time: Check if the selected date is between checkStartDate and now
            let targetDate = recurring.selectedDate ?? recurring.startDate
            if targetDate >= checkStartDate && targetDate <= currentDate {
                occurrences.append(targetDate)
            }

        case .daily:
            // Daily: Add all days between checkStartDate and now at the selected time
            let selectedTime = recurring.selectedTime ?? calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

            var currentDay = calendar.startOfDay(for: checkStartDate)
            let endDay = calendar.startOfDay(for: currentDate)

            while currentDay <= endDay {
                if let scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 12, minute: timeComponents.minute ?? 0, second: 0, of: currentDay) {
                    // Only add if the scheduled time has passed
                    if scheduledDate <= currentDate {
                        occurrences.append(scheduledDate)
                    }
                }
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
            }

        case .weekly:
            // Weekly: Find all matching weekdays at 12:00 PM
            guard let targetWeekday = recurring.selectedDayOfWeek else { break }

            var currentDay = calendar.startOfDay(for: checkStartDate)
            let endDay = calendar.startOfDay(for: currentDate)

            while currentDay <= endDay {
                let weekday = calendar.component(.weekday, from: currentDay)
                if weekday == targetWeekday {
                    if let scheduledDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDay) {
                        if scheduledDate <= currentDate {
                            occurrences.append(scheduledDate)
                        }
                    }
                }
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
            }

        case .monthly:
            // Monthly: Find all matching days of month at 12:00 PM
            guard let targetDay = recurring.selectedDayOfMonth else { break }

            var currentMonth = calendar.dateComponents([.year, .month], from: checkStartDate)
            let endMonth = calendar.dateComponents([.year, .month], from: currentDate)

            // Convert to comparable format
            let endMonthValue = (endMonth.year ?? 0) * 12 + (endMonth.month ?? 0)

            while ((currentMonth.year ?? 0) * 12 + (currentMonth.month ?? 0)) <= endMonthValue {
                // Get number of days in this month
                let monthDate = calendar.date(from: currentMonth) ?? Date()
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30

                // Use target day or last day of month if target doesn't exist
                let actualDay = min(targetDay, daysInMonth)

                currentMonth.day = actualDay
                if let scheduledDate = calendar.date(from: currentMonth),
                   let scheduledDateTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: scheduledDate) {
                    // Only add if it's within our check range and has passed
                    if scheduledDateTime >= checkStartDate && scheduledDateTime <= currentDate {
                        occurrences.append(scheduledDateTime)
                    }
                }

                // Move to next month
                currentMonth.day = 1
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: currentMonth) ?? Date()) {
                    currentMonth = calendar.dateComponents([.year, .month], from: nextMonth)
                }
            }

        case .yearly:
            // Yearly: Find all matching months (1st of month) at 12:00 PM
            guard let targetMonth = recurring.selectedMonthOfYear else { break }

            let startYear = calendar.component(.year, from: checkStartDate)
            let endYear = calendar.component(.year, from: currentDate)

            for year in startYear...endYear {
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = targetMonth
                dateComponents.day = 1
                dateComponents.hour = 12
                dateComponents.minute = 0
                dateComponents.second = 0

                if let scheduledDate = calendar.date(from: dateComponents),
                   scheduledDate >= checkStartDate && scheduledDate <= currentDate {
                    occurrences.append(scheduledDate)
                }
            }
        }

        return occurrences
    }

    
    // === CALCULATED PROPERTIES ===
    
    // Get expenses for the current budget period only
    var currentPeriodExpenses: [Expense] {
        guard let budget = budget else { return [] }
        let calendar = Calendar.current
        let now = Date()
        
        return expenses.filter { expense in
            switch budget.period {
            case .daily:
                // Only expenses from today
                return calendar.isDate(expense.date, inSameDayAs: now)
            case .weekly:
                // Only expenses from this week (Sunday to Saturday)
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                // Only expenses from this month
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
            case .yearly:
                // Only expenses from this year
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    // Total spent in the current budget period only
    var totalSpent: Double {
        currentPeriodExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var remainingAmount: Double {
        guard let budget = budget else { return 0 }
        return max(0, budget.amount - totalSpent) // Budget minus spent (can't go below 0)
    }
    
    var progressPercentage: Double {
        guard let budget = budget, budget.amount > 0 else { return 0 }
        return min(100, (totalSpent / budget.amount) * 100) // Percentage spent (max 100%)
    }
    
    // MARK: - Daily Goal Tracking
    
    // Calculate the daily spending goal based on budget period
    var dailySpendingGoal: Double {
        guard let budget = budget else { return 0 }
        
        switch budget.period {
        case .daily:
            return budget.amount
        case .weekly:
            return budget.amount / 7
        case .monthly:
            let calendar = Calendar.current
            let now = Date()
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            return budget.amount / Double(daysInMonth)
        case .yearly:
            return budget.amount / 365
        }
    }
    
    // Calculate how much you should have spent by now in the current period
    var expectedSpendingByNow: Double {
        guard let budget = budget else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        
        switch budget.period {
        case .daily:
            // For daily budgets, you should spend the full amount by end of day
            let startOfDay = calendar.startOfDay(for: now)
            let timeElapsedToday = now.timeIntervalSince(startOfDay)
            let totalSecondsInDay: TimeInterval = 24 * 60 * 60
            let dayProgress = min(1.0, timeElapsedToday / totalSecondsInDay)
            return budget.amount * dayProgress
            
        case .weekly:
            // Calculate days elapsed in current week
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let daysElapsed = calendar.dateComponents([.day], from: startOfWeek, to: now).day ?? 0
            let dayProgress = calendar.component(.hour, from: now) >= 12 ? 1.0 : 0.5 // Add partial day
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
            
        case .monthly:
            // Calculate days elapsed in current month
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let daysElapsed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 0
            let dayProgress = calendar.component(.hour, from: now) >= 12 ? 1.0 : 0.5 // Add partial day
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
            
        case .yearly:
            // Calculate days elapsed in current year
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let daysElapsed = calendar.dateComponents([.day], from: startOfYear, to: now).day ?? 0
            let dayProgress = calendar.component(.hour, from: now) >= 12 ? 1.0 : 0.5 // Add partial day
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
        }
    }
    
    // Check if you're on track with your spending goal
    var spendingStatus: SpendingStatus {
        let expected = expectedSpendingByNow
        let actual = totalSpent
        
        if actual <= expected * 0.9 {
            return .underBudget
        } else if actual <= expected * 1.1 {
            return .onTrack  
        } else {
            return .overBudget
        }
    }
    
    // Get spending status for a specific date
    func getSpendingStatus(for date: Date) -> SpendingStatus {
        guard let budget = budget else { return .onTrack }
        
        // Get expenses up to the specified date in current period
        let calendar = Calendar.current
        let expensesUpToDate = currentPeriodExpenses.filter { expense in
            expense.date <= date
        }
        let spentUpToDate = expensesUpToDate.reduce(0) { $0 + $1.amount }
        
        // Calculate expected spending by that date
        let expectedByDate = getExpectedSpending(for: date)
        
        if spentUpToDate <= expectedByDate * 0.9 {
            return .underBudget
        } else if spentUpToDate <= expectedByDate * 1.1 {
            return .onTrack
        } else {
            return .overBudget
        }
    }
    
    // Calculate expected spending by a specific date
    func getExpectedSpending(for date: Date) -> Double {
        guard let budget = budget else { return 0 }
        let calendar = Calendar.current
        
        switch budget.period {
        case .daily:
            // For daily budget, expected spending increases throughout the day
            let startOfDay = calendar.startOfDay(for: date)
            let timeElapsed = date.timeIntervalSince(startOfDay)
            let totalSecondsInDay: TimeInterval = 24 * 60 * 60
            let dayProgress = min(1.0, timeElapsed / totalSecondsInDay)
            return budget.amount * dayProgress
            
        case .weekly:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let daysElapsed = calendar.dateComponents([.day], from: startOfWeek, to: date).day ?? 0
            let dayProgress = calendar.component(.hour, from: date) >= 12 ? 1.0 : 0.5
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
            
        case .monthly:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let daysElapsed = calendar.dateComponents([.day], from: startOfMonth, to: date).day ?? 0
            let dayProgress = calendar.component(.hour, from: date) >= 12 ? 1.0 : 0.5
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
            
        case .yearly:
            let startOfYear = calendar.dateInterval(of: .year, for: date)?.start ?? date
            let daysElapsed = calendar.dateComponents([.day], from: startOfYear, to: date).day ?? 0
            let dayProgress = calendar.component(.hour, from: date) >= 12 ? 1.0 : 0.5
            return dailySpendingGoal * (Double(daysElapsed) + dayProgress)
        }
    }
    
    // === BUDGET OPERATIONS ===
    func setBudget(_ amount: Double, period: BudgetPeriod, applyToAllMonths: Bool = false) {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        print("=== setBudget called ===")
        print("Amount: $\(amount)")
        print("Period: \(period.rawValue)")
        print("Apply to all months: \(applyToAllMonths)")
        print("Current month/year: \(currentMonth)/\(currentYear)")
        print("Budgets before change: \(budgets.count) entries")
        for (index, budget) in budgets.enumerated() {
            print("  [\(index)] \(budget.month)/\(budget.year): $\(budget.amount)")
        }

        // Check if this is the very first budget being set (onboarding)
        let isFirstBudget = budgets.isEmpty

        if isFirstBudget {
            print(">>> First budget setup - initializing ALL months with expenses")
            // Find all unique months that have expenses
            var monthsToInitialize = Set<String>()
            for expense in expenses {
                let expenseMonth = calendar.component(.month, from: expense.date)
                let expenseYear = calendar.component(.year, from: expense.date)
                monthsToInitialize.insert("\(expenseYear)-\(expenseMonth)")
            }
            // Always include current month
            monthsToInitialize.insert("\(currentYear)-\(currentMonth)")

            // Create budget entries for all those months
            for monthYear in monthsToInitialize {
                let components = monthYear.split(separator: "-")
                if components.count == 2,
                   let year = Int(components[0]),
                   let month = Int(components[1]) {
                    let newBudget = Budget(
                        amount: amount,
                        period: period,
                        month: month,
                        year: year,
                        dateCreated: now
                    )
                    budgets.append(newBudget)
                    print("    Initialized budget for \(month)/\(year): $\(amount)")
                }
            }
        } else if applyToAllMonths {
            print(">>> Applying to ALL existing months")
            // Apply to all existing budget entries
            for (index, budget) in budgets.enumerated() {
                budgets[index] = Budget(
                    amount: amount,
                    period: period,
                    month: budget.month,
                    year: budget.year,
                    dateCreated: budget.dateCreated
                )
            }
        } else {
            print(">>> Applying to CURRENT month only")
            // Only update/create the current month's budget
            if let existingIndex = budgets.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
                print("    Found existing budget at index \(existingIndex), updating it")
                budgets[existingIndex] = Budget(
                    amount: amount,
                    period: period,
                    month: currentMonth,
                    year: currentYear,
                    dateCreated: budgets[existingIndex].dateCreated
                )
            } else {
                print("    No existing budget found, creating new one for current month")
                let newBudget = Budget(
                    amount: amount,
                    period: period,
                    month: currentMonth,
                    year: currentYear,
                    dateCreated: now
                )
                budgets.append(newBudget)
            }
        }

        print("Budgets after change: \(budgets.count) entries")
        for (index, budget) in budgets.enumerated() {
            print("  [\(index)] \(budget.month)/\(budget.year): $\(budget.amount)")
        }
        print("=== setBudget complete ===\n")

        saveData() // Persist to storage
        objectWillChange.send() // Notify observers
    }

    // Get budget for a specific date
    func getBudget(for date: Date) -> Budget? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        print(">>> getBudget called for \(month)/\(year)")

        // Find budget for this specific month/year - NO FALLBACK
        if let budget = budgets.first(where: { $0.month == month && $0.year == year }) {
            print("    Found exact match: $\(budget.amount)")
            return budget
        }

        print("    No budget found for \(month)/\(year)")
        return nil
    }
    
    func addExpense(_ amount: Double, note: String, category: ExpenseCategory = .other, date: Date = Date(), recurringExpenseId: UUID? = nil, sendNotification: Bool = true) {
        let expense = Expense(amount: amount, note: note, date: date, category: category, recurringExpenseId: recurringExpenseId)
        expenses.append(expense) // Add to expenses list
        saveData() // Persist to storage

        // Send expense confirmation notification immediately (unless called from notification handler)
        if sendNotification {
            notificationManager?.scheduleExpenseConfirmation(amount: amount, category: category.rawValue.capitalized, at: date)
        }
    }

    func addExpense(_ amount: Double, note: String, customCategory: CustomCategory, date: Date = Date(), recurringExpenseId: UUID? = nil, sendNotification: Bool = true) {
        let expense = Expense(amount: amount, note: note, date: date, customCategory: customCategory, recurringExpenseId: recurringExpenseId)
        expenses.append(expense) // Add to expenses list
        saveData() // Persist to storage

        // Send expense confirmation notification immediately (unless called from notification handler)
        if sendNotification {
            notificationManager?.scheduleExpenseConfirmation(amount: amount, category: customCategory.name, at: date)
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        print("DEBUG: Deleting expense with ID: \(expense.id)")
        print("DEBUG: Before deletion - Total expenses: \(expenses.count)")
        expenses.removeAll { $0.id == expense.id }
        print("DEBUG: After deletion - Total expenses: \(expenses.count)")

        // Clean up orphaned deleted recurring expenses
        cleanupOrphanedDeletedRecurringExpenses()

        saveData() // Persist to storage
        print("DEBUG: Save completed")
    }
    
    func deleteExpensesForCategory(_ categoryId: UUID) {
        expenses.removeAll { expense in
            expense.effectiveCategory.id == categoryId
        }
        saveData() // Persist to storage
    }

    func updateSubcategoryName(oldName: String, newName: String, categoryId: UUID) {
        var hasChanges = false

        // Update all expenses with the old subcategory name in the matching category
        for i in 0..<expenses.count {
            if expenses[i].categoryId == categoryId && expenses[i].note == oldName {
                // Create a new expense with updated note
                let updatedExpense = Expense(
                    amount: expenses[i].amount,
                    note: newName,
                    date: expenses[i].date,
                    categoryId: categoryId,
                    recurringExpenseId: expenses[i].recurringExpenseId
                )
                expenses[i] = updatedExpense
                hasChanges = true
            }
        }

        // Update all recurring expenses with the old subcategory name
        for i in 0..<recurringExpenses.count {
            if recurringExpenses[i].customCategory?.id == categoryId && recurringExpenses[i].note == oldName {
                // Recreate recurring expense with new note
                let old = recurringExpenses[i]
                let updated = RecurringExpense(
                    amount: old.amount,
                    note: newName,
                    category: old.category,
                    customCategory: old.customCategory,
                    recurrenceType: old.recurrenceType,
                    startDate: old.startDate,
                    selectedDate: old.selectedDate,
                    selectedTime: old.selectedTime,
                    selectedDayOfWeek: old.selectedDayOfWeek,
                    selectedDayOfMonth: old.selectedDayOfMonth,
                    selectedMonthOfYear: old.selectedMonthOfYear
                )
                // Preserve state
                recurringExpenses[i] = updated
                recurringExpenses[i].isActive = old.isActive
                recurringExpenses[i].lastProcessedDate = old.lastProcessedDate
                hasChanges = true
            }
        }

        if hasChanges {
            saveData()
        }
    }
    
    func updateExpense(_ expense: Expense, newAmount: Double, newNote: String, newCategory: CustomCategory, newDate: Date) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            // Create a new expense with the custom category initializer
            let updatedExpense = Expense(
                amount: newAmount,
                note: newNote,
                date: newDate,
                customCategory: newCategory,
                recurringExpenseId: expense.recurringExpenseId // Preserve the recurring expense ID
            )

            // Replace the expense in the array
            expenses[index] = updatedExpense
            saveData() // Persist to storage
        }
    }

    func updateExpense(_ expense: Expense, newAmount: Double, newNote: String, newCategory: CustomCategory, newDate: Date, newRecurringExpenseId: UUID?) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            // Create a new expense with the custom category initializer and updated recurring ID
            let updatedExpense = Expense(
                amount: newAmount,
                note: newNote,
                date: newDate,
                customCategory: newCategory,
                recurringExpenseId: newRecurringExpenseId
            )

            // Replace the expense in the array
            expenses[index] = updatedExpense
            saveData() // Persist to storage
        }
    }

    func resetBudget() {
        print("resetBudget() called") // Debug log
        print("Budget before reset: \(budget?.period.rawValue ?? "nil")")
        
        budgets = []     // Clear all budgets
        expenses = []    // Clear all expenses

        // Remove data from UserDefaults
        UserDefaults.standard.removeObject(forKey: budgetsKey)
        UserDefaults.standard.removeObject(forKey: expensesKey)
        
        print("Budget after reset: \(budget?.period.rawValue ?? "nil")")
        print("Expenses count after reset: \(expenses.count)")
    }
    
    // === DATA PERSISTENCE (LOADS DATA FROM DEVICE STORAGE) ===
    private func loadData() {
        // Load saved budgets from UserDefaults
        if let budgetsData = UserDefaults.standard.data(forKey: budgetsKey),
           let decodedBudgets = try? JSONDecoder().decode([Budget].self, from: budgetsData) {
            self.budgets = decodedBudgets
        }

        // Load saved expenses from UserDefaults
        if let expensesData = UserDefaults.standard.data(forKey: expensesKey),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: expensesData) {
            self.expenses = decodedExpenses
        }

        // Load recurring expenses from UserDefaults
        if let recurringData = UserDefaults.standard.data(forKey: recurringExpensesKey),
           let recurringExpenses = try? JSONDecoder().decode([RecurringExpense].self, from: recurringData) {
            self.recurringExpenses = recurringExpenses
        }

        // Load deleted recurring expenses from UserDefaults
        if let deletedRecurringData = UserDefaults.standard.data(forKey: deletedRecurringExpensesKey),
           let deletedRecurringExpenses = try? JSONDecoder().decode([RecurringExpense].self, from: deletedRecurringData) {
            self.deletedRecurringExpenses = deletedRecurringExpenses
            print("💾 Loaded \(deletedRecurringExpenses.count) deleted recurring expenses")
        } else {
            print("💾 No deleted recurring expenses found in storage")
        }
    }
    
    // === DATA PERSISTENCE (SAVES DATA TO DEVICE STORAGE) ===
    func saveData() {
        // Save all budgets to UserDefaults
        if let encodedBudgets = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(encodedBudgets, forKey: budgetsKey)
        }

        // Save current expenses to UserDefaults
        if let encodedExpenses = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedExpenses, forKey: expensesKey)
        }

        // Save recurring expenses to UserDefaults
        if let recurringData = try? JSONEncoder().encode(recurringExpenses) {
            UserDefaults.standard.set(recurringData, forKey: recurringExpensesKey)
        }

        // Save deleted recurring expenses to UserDefaults
        if let deletedRecurringData = try? JSONEncoder().encode(deletedRecurringExpenses) {
            UserDefaults.standard.set(deletedRecurringData, forKey: deletedRecurringExpensesKey)
            print("💾 Saved \(deletedRecurringExpenses.count) deleted recurring expenses")
        } else {
            print("⚠️ Failed to encode deleted recurring expenses")
        }

        // Force immediate synchronization to disk
        UserDefaults.standard.synchronize()
    }
}