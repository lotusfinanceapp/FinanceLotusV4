import Foundation
import SwiftUI

// MARK: - Data Manager - HANDLES ALL DATA OPERATIONS
class BudgetDataManager: ObservableObject {
    @Published var budget: Budget?           // Current budget (nil if no budget set)
    @Published var expenses: [Expense] = []  // List of all logged expenses
    
    // === STORAGE KEYS ===
    private let budgetKey = "budget"         // UserDefaults key for budget storage
    private let expensesKey = "expenses"     // UserDefaults key for expenses storage
    
    init() {
        loadData() // Load saved data when app starts
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
    func setBudget(_ amount: Double, period: BudgetPeriod) {
        let newBudget = Budget(amount: amount, period: period, dateCreated: Date())
        self.budget = newBudget
        saveData() // Persist to storage
    }
    
    func addExpense(_ amount: Double, note: String, category: ExpenseCategory = .other) {
        let expense = Expense(amount: amount, note: note, date: Date(), category: category)
        expenses.append(expense) // Add to expenses list
        saveData() // Persist to storage
    }
    
    func addExpense(_ amount: Double, note: String, customCategory: CustomCategory) {
        let expense = Expense(amount: amount, note: note, date: Date(), customCategory: customCategory)
        expenses.append(expense) // Add to expenses list
        saveData() // Persist to storage
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveData() // Persist to storage
    }
    
    func deleteExpensesForCategory(_ categoryId: UUID) {
        expenses.removeAll { expense in
            expense.effectiveCategory.id == categoryId
        }
        saveData() // Persist to storage
    }
    
    func updateExpense(_ expense: Expense, newAmount: Double, newNote: String, newCategory: CustomCategory, newDate: Date) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            // Create a new expense with the custom category initializer
            let updatedExpense = Expense(
                amount: newAmount,
                note: newNote,
                date: newDate,
                customCategory: newCategory
            )
            
            // Replace the expense in the array
            expenses[index] = updatedExpense
            saveData() // Persist to storage
        }
    }
    
    func resetBudget() {
        print("resetBudget() called") // Debug log
        print("Budget before reset: \(budget?.period.rawValue ?? "nil")")
        
        budget = nil     // Clear budget
        expenses = []    // Clear all expenses
        
        // Remove data from UserDefaults
        UserDefaults.standard.removeObject(forKey: budgetKey)
        UserDefaults.standard.removeObject(forKey: expensesKey)
        
        print("Budget after reset: \(budget?.period.rawValue ?? "nil")")
        print("Expenses count after reset: \(expenses.count)")
    }
    
    // === DATA PERSISTENCE (LOADS DATA FROM DEVICE STORAGE) ===
    private func loadData() {
        // Load saved budget from UserDefaults
        if let budgetData = UserDefaults.standard.data(forKey: budgetKey),
           let decodedBudget = try? JSONDecoder().decode(Budget.self, from: budgetData) {
            self.budget = decodedBudget
        }
        
        // Load saved expenses from UserDefaults
        if let expensesData = UserDefaults.standard.data(forKey: expensesKey),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: expensesData) {
            self.expenses = decodedExpenses
        }
    }
    
    // === DATA PERSISTENCE (SAVES DATA TO DEVICE STORAGE) ===
    private func saveData() {
        // Save current budget to UserDefaults
        if let budget = budget,
           let encodedBudget = try? JSONEncoder().encode(budget) {
            UserDefaults.standard.set(encodedBudget, forKey: budgetKey)
        }
        
        // Save current expenses to UserDefaults
        if let encodedExpenses = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encodedExpenses, forKey: expensesKey)
        }
    }
}