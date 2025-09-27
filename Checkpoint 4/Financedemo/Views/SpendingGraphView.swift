import SwiftUI

enum TimePeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var icon: String {
            switch self {
            case .daily: return "calendar"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.badge.plus"
            }
        }
        
        var dataPoints: Int {
            switch self {
            case .daily: return 7    // Show 7 days
            case .weekly: return 5   // Show 5 weeks
            case .monthly: return 6  // Show 6 months
            }
        }
    }

struct SpendingGraphView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showElements = false
    @State private var selectedPeriod: TimePeriod = .daily
    @State private var periodOffset: Int = 0 // 0 = current period, -1 = previous, +1 = next
    @State private var maxScaleValue: Double? = nil // Sticky max value for Y-axis scaling
    @State private var selectedPointIndex: Int? = nil // Track which point is selected
    
    private let initialSelectedIndex: Int?
    
    init(dataManager: BudgetDataManager, initialSelectedIndex: Int? = nil) {
        self.dataManager = dataManager
        self.initialSelectedIndex = initialSelectedIndex
    }
    
    // Calculate period statistics
    private var periodTotal: Double {
        dailySpendingData.reduce(0) { $0 + $1.1 }
    }
    
    private var dailyAverage: Double {
        let totalDays = selectedPeriod == .daily ? 7 : (selectedPeriod == .weekly ? 35 : 180)
        return periodTotal / Double(totalDays)
    }
    
    private var highestDay: Double {
        dailySpendingData.map { $0.1 }.max() ?? 0
    }
    
    private var activePeriods: Int {
        dailySpendingData.filter { $0.1 > 0 }.count
    }
    
    // Navigation availability
    private var canNavigateLeft: Bool {
        // Can always navigate to past (no limit on historical data)
        return true
    }
    
    private var canNavigateRight: Bool {
        // Can only navigate back to present (periodOffset = 0)
        return periodOffset > 0
    }
    
    // Current period label for navigation indicator
    private var currentPeriodLabel: String {
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedPeriod {
        case .daily:
            if periodOffset == 0 {
                return "This Week"
            } else {
                return "\(periodOffset) week\(periodOffset == 1 ? "" : "s") ago"
            }
        case .weekly:
            if periodOffset == 0 {
                return "Recent weeks"
            } else {
                let startWeek = periodOffset * 5
                let endWeek = startWeek + 4
                return "\(startWeek)-\(endWeek) weeks ago"
            }
        case .monthly:
            if periodOffset == 0 {
                return "Recent Months"
            } else {
                let years = Double(periodOffset * 6) / 12.0
                if years == 1.0 {
                    return "1 year ago"
                } else if years.truncatingRemainder(dividingBy: 1.0) == 0.5 {
                    return "\(Int(years)).5 years ago"
                } else {
                    return "\(Int(years)) years ago"
                }
            }
        }
    }
    
    // Calculate spending data based on selected period type
    private var dailySpendingData: [(String, Double)] {
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedPeriod {
        case .daily:
            return calculateDailyData(calendar: calendar, today: today)
        case .weekly:
            return calculateWeeklyData(calendar: calendar, today: today)
        case .monthly:
            return calculateMonthlyData(calendar: calendar, today: today)
        }
    }
    
    // Calculate smart max value with dynamic scaling behavior
    private var stableMaxValue: Double {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current period data to check for high values
        let currentData = getCurrentPeriodData(calendar: calendar, today: today)
        let currentMax = currentData.max() ?? 0
        
        // If we have a sticky max value and current data doesn't exceed it significantly, use sticky value
        if let stickyMax = maxScaleValue, currentMax < stickyMax * 0.8 {
            return stickyMax
        }
        
        // Default behavior: use last 2 periods for scaling (unless we're viewing older periods)
        let offsetRange = periodOffset <= 1 ? 0...1 : max(0, periodOffset-1)...periodOffset+1
        var allValues: [Double] = []
        
        for offset in offsetRange {
            let data: [(String, Double)]
            
            switch selectedPeriod {
            case .daily:
                data = calculateDailyDataWithOffset(calendar: calendar, today: today, offset: offset)
            case .weekly:
                data = calculateWeeklyDataWithOffset(calendar: calendar, today: today, offset: offset)
            case .monthly:
                data = calculateMonthlyDataWithOffset(calendar: calendar, today: today, offset: offset)
            }
            
            allValues.append(contentsOf: data.map { $0.1 })
        }
        
        let dataMax = allValues.max() ?? 100
        let newMaxValue = max(dataMax * 1.2, 50) // Add 20% padding, minimum scale of 50
        
        return newMaxValue
    }
    
    // Get current period data values
    private func getCurrentPeriodData(calendar: Calendar, today: Date) -> [Double] {
        // Ensure calendar uses Sunday as first day of week
        var cal = calendar
        cal.firstWeekday = 1 // 1 = Sunday
        
        let data: [(String, Double)]
        
        switch selectedPeriod {
        case .daily:
            data = calculateDailyDataWithOffset(calendar: cal, today: today, offset: periodOffset)
        case .weekly:
            data = calculateWeeklyDataWithOffset(calendar: cal, today: today, offset: periodOffset)
        case .monthly:
            data = calculateMonthlyDataWithOffset(calendar: cal, today: today, offset: periodOffset)
        }
        
        return data.map { $0.1 }
    }
    
    // Update sticky max value when swiping to maintain consistent scaling
    private func updateStickyMaxValue() {
        let currentMax = stableMaxValue
        
        // Update sticky value if current scale is higher, or if we don't have one yet
        if maxScaleValue == nil || currentMax > (maxScaleValue ?? 0) {
            maxScaleValue = currentMax
        }
    }
    
    // Daily view: Show individual days (7 days)
    private func calculateDailyData(calendar: Calendar, today: Date) -> [(String, Double)] {
        return calculateDailyDataWithOffset(calendar: calendar, today: today, offset: periodOffset)
    }
    
    private func calculateDailyDataWithOffset(calendar: Calendar, today: Date, offset: Int) -> [(String, Double)] {
        // Ensure calendar uses Sunday as first day of week
        var cal = calendar
        cal.firstWeekday = 1 // 1 = Sunday
        
        let adjustedToday = cal.date(byAdding: .weekOfYear, value: -offset, to: today) ?? today
        let adjustedTodayStart = cal.startOfDay(for: adjustedToday)
        let startDate = cal.date(byAdding: .day, value: -6, to: adjustedTodayStart) ?? adjustedTodayStart
        var dailyTotals: [String: Double] = [:]
        
        for expense in dataManager.expenses {
            // Include today's expenses by going to end of adjustedToday instead of start
            let adjustedTodayEnd = cal.date(byAdding: .day, value: 1, to: adjustedTodayStart) ?? adjustedTodayStart
            if expense.date >= startDate && expense.date < adjustedTodayEnd {
                // Use calendar to get the start of day for the expense to ensure proper matching
                let expenseDay = cal.startOfDay(for: expense.date)
                let dayString = DateFormatter.dayFormatter.string(from: expenseDay)
                dailyTotals[dayString, default: 0] += expense.amount
            }
        }
        
        var result: [(String, Double)] = []
        for i in 0..<7 {
            let date = cal.date(byAdding: .day, value: -i, to: adjustedTodayStart) ?? adjustedTodayStart
            let dayString = DateFormatter.dayFormatter.string(from: date)
            let amount = dailyTotals[dayString] ?? 0
            result.append((dayString, amount))
        }
        
        return result.reversed()
    }
    
    // Weekly view: Show combined weekly totals (5 weeks)
    private func calculateWeeklyData(calendar: Calendar, today: Date) -> [(String, Double)] {
        return calculateWeeklyDataWithOffset(calendar: calendar, today: today, offset: periodOffset)
    }
    
    private func calculateWeeklyDataWithOffset(calendar: Calendar, today: Date, offset: Int) -> [(String, Double)] {
        // Ensure calendar uses Sunday as first day of week
        var cal = calendar
        cal.firstWeekday = 1 // 1 = Sunday
        
        let adjustedToday = cal.date(byAdding: .weekOfYear, value: -offset * 5, to: today) ?? today
        
        // Get the current week interval using Sunday as start
        let currentWeekInterval = cal.dateInterval(of: .weekOfYear, for: adjustedToday) ?? DateInterval(start: adjustedToday, duration: 7*24*60*60)
        let currentWeekStart = currentWeekInterval.start
        
        var weeklyTotals: [Int: Double] = [:] // Use week index instead of date string
        
        for expense in dataManager.expenses {
            // Find which week this expense belongs to (0 = current week, 1 = 1 week ago, etc.)
            if let expenseWeekInterval = cal.dateInterval(of: .weekOfYear, for: expense.date) {
                let weeksDifference = cal.dateComponents([.weekOfYear], from: expenseWeekInterval.start, to: currentWeekStart).weekOfYear ?? 0
                
                // Only include expenses from the 5 weeks we're displaying
                if weeksDifference >= 0 && weeksDifference < 5 {
                    weeklyTotals[weeksDifference, default: 0] += expense.amount
                }
            }
        }
        
        var result: [(String, Double)] = []
        for i in 0..<5 {
            let weekLabel: String
            let actualWeekNumber = (offset * 5) + i
            if actualWeekNumber == 0 {
                weekLabel = "This Week"
            } else {
                weekLabel = "\(actualWeekNumber)"
            }
            
            let amount = weeklyTotals[i] ?? 0
            result.append((weekLabel, amount))
        }
        
        return result.reversed()
    }
    
    // Monthly view: Show combined monthly totals (6 months)
    private func calculateMonthlyData(calendar: Calendar, today: Date) -> [(String, Double)] {
        return calculateMonthlyDataWithOffset(calendar: calendar, today: today, offset: periodOffset)
    }
    
    private func calculateMonthlyDataWithOffset(calendar: Calendar, today: Date, offset: Int) -> [(String, Double)] {
        // Ensure calendar uses Sunday as first day of week (for consistency)
        var cal = calendar
        cal.firstWeekday = 1 // 1 = Sunday
        
        let adjustedToday = cal.date(byAdding: .month, value: -offset * 6, to: today) ?? today
        let adjustedTodayStart = cal.startOfDay(for: adjustedToday)
        let startDate = cal.date(byAdding: .month, value: -5, to: adjustedTodayStart) ?? adjustedTodayStart
        var monthlyTotals: [String: Double] = [:]
        
        for expense in dataManager.expenses {
            // For monthly view, we need to include expenses that fall within any of the 6 months being displayed
            // Don't use strict date range, instead check if the expense month matches any displayed month
            let expenseDay = cal.startOfDay(for: expense.date)
            let monthString = DateFormatter.monthFormatter.string(from: expenseDay)
            
            // Check if this month string will be displayed in our 6-month range
            var isInDisplayRange = false
            for i in 0..<6 {
                let displayDate = cal.date(byAdding: .month, value: -i, to: adjustedTodayStart) ?? adjustedTodayStart
                let displayMonthString = DateFormatter.monthFormatter.string(from: displayDate)
                if monthString == displayMonthString {
                    isInDisplayRange = true
                    break
                }
            }
            
            if isInDisplayRange {
                monthlyTotals[monthString, default: 0] += expense.amount
            }
        }
        
        var result: [(String, Double)] = []
        for i in 0..<6 {
            let date = cal.date(byAdding: .month, value: -i, to: adjustedTodayStart) ?? adjustedTodayStart
            let monthString = DateFormatter.monthFormatter.string(from: date)
            let amount = monthlyTotals[monthString] ?? 0
            result.append((monthString, amount))
        }
        
        return result.reversed()
    }
    
    // Simple: Just get expenses that belong to the selected period using the same date logic as the graph
    private func getExpensesForPeriod(periodIndex: Int) -> [Expense] {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday = 1
        let today = Date()
        
        switch selectedPeriod {
        case .daily:
            // Get the exact date for this daily period
            // Account for the reversal: periodIndex 0 should map to day -6, periodIndex 6 should map to day 0
            let adjustedToday = calendar.date(byAdding: .weekOfYear, value: -periodOffset, to: today) ?? today
            let reversedIndex = 6 - periodIndex  // Reverse the index to match graph's .reversed()
            let targetDate = calendar.date(byAdding: .day, value: -reversedIndex, to: adjustedToday) ?? adjustedToday
            
            return dataManager.expenses.filter { expense in
                calendar.isDate(expense.date, inSameDayAs: targetDate)
            }
            
        case .weekly:
            // Get all expenses in the target week
            // Account for the reversal: periodIndex 0 should map to week -4, periodIndex 4 should map to week 0
            let adjustedToday = calendar.date(byAdding: .weekOfYear, value: -periodOffset * 5, to: today) ?? today
            let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: adjustedToday) ?? DateInterval(start: adjustedToday, duration: TimeInterval(7*24*60*60))
            let currentWeekStart = currentWeekInterval.start
            let reversedIndex = 4 - periodIndex  // Reverse the index to match graph's .reversed()
            let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: -reversedIndex, to: currentWeekStart) ?? currentWeekStart
            let targetWeekInterval = calendar.dateInterval(of: .weekOfYear, for: targetWeekStart) ?? DateInterval(start: targetWeekStart, duration: TimeInterval(7*24*60*60))
            
            return dataManager.expenses.filter { expense in
                targetWeekInterval.contains(expense.date)
            }
            
        case .monthly:
            // Get all expenses in the target month
            // Account for the reversal: periodIndex 0 should map to month -5, periodIndex 5 should map to month 0
            let adjustedToday = calendar.date(byAdding: .month, value: -periodOffset * 6, to: today) ?? today
            let reversedIndex = 5 - periodIndex  // Reverse the index to match graph's .reversed()
            let targetDate = calendar.date(byAdding: .month, value: -reversedIndex, to: adjustedToday) ?? adjustedToday
            
            return dataManager.expenses.filter { expense in
                let expenseMonth = Calendar.current.component(.month, from: expense.date)
                let expenseYear = Calendar.current.component(.year, from: expense.date)
                let targetMonth = Calendar.current.component(.month, from: targetDate)
                let targetYear = Calendar.current.component(.year, from: targetDate)
                return expenseMonth == targetMonth && expenseYear == targetYear
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 20) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.colAccent)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5), value: showElements)
                        
                        Text("\(selectedPeriod.rawValue) Spending")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                    
                    // Period Toggle Control
                    HStack(spacing: 0) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedPeriod = period
                                    periodOffset = 0 // Reset to current period when switching
                                    maxScaleValue = nil // Reset scale when changing period type
                                    selectedPointIndex = nil // Reset selected point when switching periods
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: period.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(selectedPeriod == period ? .white : .colPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: selectedPeriod == period ? 8 : 0)
                                        .fill(selectedPeriod == period ? Color.colAccent : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.colCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showElements)
                    
                    // Period indicator as graph title with navigation arrows
                    HStack(spacing: 12) {
                        // Left arrow (go to past)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                periodOffset += 1
                                updateStickyMaxValue()
                                selectedPointIndex = nil  // Deselect any selected dot
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                                .foregroundColor(canNavigateLeft ? .colSecondaryText : .colSecondaryText.opacity(0.3))
                        }
                        .disabled(!canNavigateLeft)
                        .animation(.easeInOut(duration: 0.2), value: canNavigateLeft)
                        
                        Text(currentPeriodLabel)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                        
                        // Right arrow (go to present)
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if periodOffset > 0 {
                                    periodOffset -= 1
                                    updateStickyMaxValue()
                                    selectedPointIndex = nil  // Deselect any selected dot
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(canNavigateRight ? .colSecondaryText : .colSecondaryText.opacity(0.3))
                        }
                        .disabled(!canNavigateRight)
                        .animation(.easeInOut(duration: 0.2), value: canNavigateRight)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    
                        // Simple Line Graph
                        SimpleLineGraph(
                            data: dailySpendingData,
                            selectedPointIndex: $selectedPointIndex,
                            stableMaxValue: stableMaxValue,
                            selectedPeriod: selectedPeriod,
                            budget: dataManager.budget,
                            periodOffset: periodOffset,
                            onSwipeLeft: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    // Only allow going back toward present, prevent future periods
                                    if periodOffset > 0 {
                                        periodOffset -= 1  // Go forward toward present (but not future)
                                        updateStickyMaxValue()
                                        selectedPointIndex = nil  // Deselect any selected dot
                                    }
                                }
                            },
                            onSwipeRight: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    periodOffset += 1  // Go backward in time (past)
                                    updateStickyMaxValue()
                                    selectedPointIndex = nil  // Deselect any selected dot
                                }
                            }
                        )
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        )
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    
                    // Point Details Info Section
                    if let selectedIndex = selectedPointIndex, selectedIndex < dailySpendingData.count {
                        let selectedData = dailySpendingData[selectedIndex]
                        let currentData = dailySpendingData
                        
                        VStack(spacing: 16) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Selected Period")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colSecondaryText)
                                    
                                    Text(selectedData.0)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedPointIndex = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.colSecondaryText)
                                }
                            }
                            
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
                                    
                                    Text(selectedData.1.formattedCurrency())
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedData.1 > 0 ? .colAccent : .colSecondaryText)
                                }
                                
                                // Comparison with average
                                let average = currentData.reduce(0) { $0 + $1.1 } / Double(currentData.count)
                                let percentageDiff = average > 0 ? ((selectedData.1 - average) / average) * 100 : 0
                                
                                HStack(spacing: 8) {
                                    Image(systemName: percentageDiff >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(percentageDiff >= 0 ? .red : .green)
                                        .font(.caption)
                                    
                                    Text("\(String(format: "%.0f", abs(percentageDiff)))% \(percentageDiff >= 0 ? "above" : "below") average")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colSecondaryText)
                                    
                                    let periodName = selectedPeriod == .daily ? "day" : (selectedPeriod == .weekly ? "week" : "month")
                                    Text("(\(average.formattedCurrency())/\(periodName))")
                                        .font(.caption2)
                                        .foregroundColor(.colSecondaryText.opacity(0.8))
                                }
                                
                                // Budget goal comparison
                                if let budget = dataManager.budget {
                                    let budgetGoal = convertBudgetToCurrentPeriod(budget: budget, currentPeriod: selectedPeriod)
                                    let budgetPercentageDiff = budgetGoal > 0 ? ((selectedData.1 - budgetGoal) / budgetGoal) * 100 : 0
                                    
                                    HStack(spacing: 8) {
                                        let isOnPar = abs(budgetPercentageDiff) <= 5
                                        
                                        if isOnPar {
                                            Image(systemName: "target")
                                                .foregroundColor(.blue)
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
                                        
                                        let periodName = selectedPeriod == .daily ? "day" : (selectedPeriod == .weekly ? "week" : "month")
                                        Text("(\(budgetGoal.formattedCurrency())/\(periodName))")
                                            .font(.caption2)
                                            .foregroundColor(.colSecondaryText.opacity(0.8))
                                    }
                                }
                            }
                            
                            // Transaction Details Section
                            let periodExpenses = getExpensesForPeriod(periodIndex: selectedIndex)
                            
                            if !periodExpenses.isEmpty {
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
                                        
                                        Text("\(periodExpenses.count) transaction\(periodExpenses.count == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                    
                                    // Spending by Category
                                    let categoryTotals = Dictionary(grouping: periodExpenses) { $0.effectiveCategory }
                                        .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }
                                        .sorted { $0.value > $1.value }
                                    
                                    VStack(spacing: 8) {
                                        ForEach(Array(categoryTotals.enumerated()), id: \.offset) { index, categoryTotal in
                                            let category = categoryTotal.key
                                            let amount = categoryTotal.value
                                            let percentage = selectedData.1 > 0 ? (amount / selectedData.1) * 100 : 0
                                            
                                            HStack(spacing: 12) {
                                                // Category icon and color
                                                Image(systemName: category.icon)
                                                    .font(.caption)
                                                    .foregroundColor(category.color)
                                                    .frame(width: 16)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(category.name)
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.colPrimaryText)
                                                    
                                                    Text("\(String(format: "%.0f", percentage))% of spending")
                                                        .font(.caption2)
                                                        .foregroundColor(.colSecondaryText.opacity(0.8))
                                                }
                                                
                                                Spacer()
                                                
                                                Text(amount.formattedCurrency())
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.colPrimaryText)
                                            }
                                            
                                            // Show divider between all categories except the last one
                                            if index < categoryTotals.count - 1 {
                                                Divider()
                                                    .background(Color.colSecondaryText.opacity(0.1))
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
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPointIndex)
                    }
                    
                    // Stats Summary
                    VStack(spacing: 16) {
                        // Stats cards row 1
                        HStack(spacing: 12) {
                            // Total Spent Card
                            VStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.colAccent)
                                
                                Text(periodTotal.formattedCurrency())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text("Total Spent")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            
                            // Daily Average Card
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text(dailyAverage.formattedCurrency())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text("Daily Average")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                        
                        // Stats cards row 2
                        HStack(spacing: 12) {
                            // Highest Day Card
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text(highestDay.formattedCurrency())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text("Highest \(selectedPeriod == .daily ? "Day" : (selectedPeriod == .weekly ? "Week" : "Month"))")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            
                            // Days Active Card
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("\(activePeriods) of \(selectedPeriod.dataPoints)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text("\(selectedPeriod == .daily ? "Days" : (selectedPeriod == .weekly ? "Weeks" : "Months")) Active")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Spending Graph")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
        .onAppear {
            // Reset scale when entering the screen
            maxScaleValue = nil
            periodOffset = 0
            
            // Set initial selected point if provided
            if let initialIndex = initialSelectedIndex {
                selectedPointIndex = initialIndex
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showElements = true
            }
            
            // Configure navigation bar
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            
            withAnimation {
                showElements = true
            }
        }
    }
    
    // Helper function to convert budget amount to match the current graph period
    private func convertBudgetToCurrentPeriod(budget: Budget, currentPeriod: TimePeriod) -> Double {
        let budgetAmount = budget.amount
        let budgetPeriod = budget.period
        
        switch currentPeriod {
        case .daily:
            // Convert budget to daily amount
            switch budgetPeriod {
            case .daily:
                return budgetAmount
            case .weekly:
                return budgetAmount / 7
            case .monthly:
                // Use average days per month
                return budgetAmount / 30.44 // Average days per month
            case .yearly:
                return budgetAmount / 365
            }
            
        case .weekly:
            // Convert budget to weekly amount
            switch budgetPeriod {
            case .daily:
                return budgetAmount * 7
            case .weekly:
                return budgetAmount
            case .monthly:
                return budgetAmount / 4.33 // Average weeks per month (52 weeks / 12 months)
            case .yearly:
                return budgetAmount / 52
            }
            
        case .monthly:
            // Convert budget to monthly amount
            switch budgetPeriod {
            case .daily:
                return budgetAmount * 30.44 // Average days per month
            case .weekly:
                return budgetAmount * 4.33 // Average weeks per month
            case .monthly:
                return budgetAmount
            case .yearly:
                return budgetAmount / 12
            }
        }
    }
}

struct SimpleLineGraph: View {
    let data: [(String, Double)]
    @Binding var selectedPointIndex: Int?
    let stableMaxValue: Double
    let selectedPeriod: TimePeriod
    let budget: Budget?
    let periodOffset: Int
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    private var maxValue: Double {
        return stableMaxValue
    }
    
    private var formattedMaxValue: String {
        if maxValue >= 1000 {
            return String(format: "%.0fk", maxValue / 1000)
        } else {
            return String(format: "%.0f", maxValue)
        }
    }
    
    private var selectedPointData: (String, Double)? {
        guard let index = selectedPointIndex, index < data.count else { return nil }
        return data[index]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart area with proper grid alignment
            GeometryReader { geometry in
                let chartWidth = geometry.size.width - 60 // Leave space for Y labels
                let chartHeight = geometry.size.height - 30 // Leave space for X labels
                let startX: CGFloat = 50
                let startY: CGFloat = 10
                
                ZStack {
                    // Chart background with tap to dismiss and swipe navigation
                    Rectangle()
                        .fill(Color.colInputBackground.opacity(0.1))
                        .frame(width: chartWidth, height: chartHeight)
                        .position(x: startX + chartWidth/2, y: startY + chartHeight/2)
                        .cornerRadius(8)
                        .onTapGesture {
                            // Only dismiss if there's actually a selection
                            if selectedPointIndex != nil {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPointIndex = nil
                                }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let horizontalDistance = value.translation.width
                                    let verticalDistance = abs(value.translation.height)
                                    
                                    // Only respond to primarily horizontal swipes
                                    if abs(horizontalDistance) > 50 && abs(horizontalDistance) > verticalDistance * 2 {
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        
                                        if horizontalDistance > 0 {
                                            // Swipe right - go to previous period
                                            onSwipeRight()
                                        } else {
                                            // Swipe left - go to next period
                                            onSwipeLeft()
                                        }
                                    }
                                }
                        )
                        .zIndex(-1) // Put background behind everything
                    
                    // Horizontal grid lines and Y labels
                    ForEach(0..<5) { i in
                        let y = startY + CGFloat(i) * (chartHeight / 4)
                        let value = maxValue * (1.0 - Double(i) / 4.0)
                        
                        // Grid line
                        Path { path in
                            path.move(to: CGPoint(x: startX, y: y))
                            path.addLine(to: CGPoint(x: startX + chartWidth, y: y))
                        }
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        
                        // Y label
                        Text(formatValue(value))
                            .font(.caption2)
                            .foregroundColor(.colSecondaryText)
                            .position(x: 25, y: y)
                    }
                    
                    // Vertical grid lines
                    if !data.isEmpty {
                        ForEach(0..<data.count, id: \.self) { i in
                            let x = startX + (chartWidth * CGFloat(i) / CGFloat(max(data.count - 1, 1)))
                            
                            Path { path in
                                path.move(to: CGPoint(x: x, y: startY))
                                path.addLine(to: CGPoint(x: x, y: startY + chartHeight))
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        }
                    }
                    
                    // Budget reset lines based on actual budget period
                    ForEach(Array(getBudgetResetInfo().enumerated()), id: \.offset) { _, resetInfo in
                        let x = startX + (chartWidth * CGFloat(resetInfo.index) / CGFloat(max(data.count - 1, 1)))
                        
                        // Dotted vertical line
                        Path { path in
                            let dashLength: CGFloat = 4
                            let gapLength: CGFloat = 3
                            var currentY = startY
                            
                            while currentY < startY + chartHeight {
                                path.move(to: CGPoint(x: x, y: currentY))
                                path.addLine(to: CGPoint(x: x, y: min(currentY + dashLength, startY + chartHeight)))
                                currentY += dashLength + gapLength
                            }
                        }
                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                        
                        // Budget reset label
                        VStack {
                            Text("Budget Reset")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            Text(resetInfo.label)
                                .font(.caption2)
                                .foregroundColor(.blue.opacity(0.7))
                        }
                        .padding(4)
                        .background(Color.colBackground.opacity(0.9))
                        .cornerRadius(6)
                        .position(x: x, y: startY - 20)
                    }
                    
                    // Data line and points
                    if !data.isEmpty && data.count > 1 {
                        // Line path
                        Path { path in
                            for (index, item) in data.enumerated() {
                                let x = startX + (chartWidth * CGFloat(index) / CGFloat(max(data.count - 1, 1)))
                                let normalizedValue = CGFloat(item.1 / maxValue)
                                let y = startY + chartHeight - (normalizedValue * chartHeight)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.colAccent.opacity(0.8), .colAccent]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                    }
                    
                    // Data points - Interactive
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        let x = startX + (chartWidth * CGFloat(index) / CGFloat(max(data.count - 1, 1)))
                        let normalizedValue = CGFloat(item.1 / maxValue)
                        let y = startY + chartHeight - (normalizedValue * chartHeight)
                        let isSelected = selectedPointIndex == index
                        
                        ZStack {
                            // Invisible but touchable tap area
                            Circle()
                                .fill(Color.white.opacity(0.001)) // Nearly invisible but still touchable
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    print("DEBUG: Dot \(index) tapped! Current selected: \(String(describing: selectedPointIndex))")
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedPointIndex = index
                                    }
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            
                            // Visible dot
                            Circle()
                                .fill(Color.colAccent)
                                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.colAccent.opacity(0.3), lineWidth: isSelected ? 8 : 0)
                                )
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                                .allowsHitTesting(false) // Prevent double tap handling
                        }
                        .position(x: x, y: y)
                        .zIndex(10) // Put data points on top
                    }
                    
                    // Custom popup for selected point
                    if let selectedIndex = selectedPointIndex, selectedIndex < data.count {
                        let selectedData = data[selectedIndex]
                        let x = startX + (chartWidth * CGFloat(selectedIndex) / CGFloat(max(data.count - 1, 1)))
                        let normalizedValue = CGFloat(selectedData.1 / maxValue)
                        let y = startY + chartHeight - (normalizedValue * chartHeight)
                        let bubbleInfo = calculateBubblePosition(x: x, y: y, chartWidth: chartWidth, chartHeight: chartHeight, startX: startX, startY: startY)
                        
                        // Generate appropriate popup label based on period type
                        let popupLabel: String = {
                            if selectedPeriod == .weekly {
                                if selectedData.0 == "This Week" {
                                    return "This Week"
                                } else if let weekNumber = Int(selectedData.0) {
                                    return "\(weekNumber) weeks ago"
                                } else {
                                    return selectedData.0
                                }
                            } else {
                                return selectedData.0
                            }
                        }()
                        
                        let _ = print("DEBUG: Rendering popup for index \(selectedIndex), data: \(selectedData.0) = $\(selectedData.1)")
                        
                        // Speech bubble popup
                        ZStack(alignment: bubbleInfo.tailPointsUp ? .top : .bottom) {
                            // Bubble content (compact)
                            VStack(alignment: .center, spacing: 2) {
                                Text(popupLabel)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.colSecondaryText)
                                
                                if selectedData.1 == 0 {
                                    Text("$0.00")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)
                                } else {
                                    Text(selectedData.1.formattedCurrency())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.colAccent)
                                }
                            }
                            .padding(10)
                            .background(
                                // Speech bubble shape with tail
                                SpeechBubbleShape(tailPointsUp: bubbleInfo.tailPointsUp)
                                    .fill(Color.colCardBackground.opacity(0.95))
                                    .overlay(
                                        SpeechBubbleShape(tailPointsUp: bubbleInfo.tailPointsUp)
                                            .stroke(Color.colAccent.opacity(0.6), lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            )
                        }
                        .position(x: x, y: bubbleInfo.position) // Smart positioning
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedPointIndex)
                        .zIndex(20) // Put popup on top of everything
                    }
                }
            }
            
            // X-axis labels - positioned exactly on grid lines
            GeometryReader { geometry in
                let chartWidth = geometry.size.width - 60
                let startX: CGFloat = 50
                
                ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                    let x = startX + (chartWidth * CGFloat(index) / CGFloat(max(data.count - 1, 1)))
                    
                    Text(dayData.0)
                        .font(.caption2)
                        .foregroundColor(.colSecondaryText)
                        .position(x: x, y: 12)
                }
            }
            .frame(height: 25)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fk", value / 1000)
        } else if value >= 100 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    // Smart positioning for speech bubble to avoid covering other points
    private func calculateBubblePosition(x: CGFloat, y: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat, startX: CGFloat, startY: CGFloat) -> (position: CGFloat, tailPointsUp: Bool) {
        let bubbleHeight: CGFloat = 40
        let minDistanceFromEdge: CGFloat = 35
        
        // Default position above the dot
        let preferredY = y - bubbleHeight
        
        // Check if it would be too close to top edge
        if preferredY < startY + minDistanceFromEdge {
            // Position below the dot instead
            return (y + bubbleHeight, true) // Tail points up when bubble is below
        }
        
        return (max(preferredY, minDistanceFromEdge), false) // Tail points down when bubble is above
    }
    
    // Format currency values for display in speech bubble
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    // Helper function to find budget reset points based on actual budget period
    private func getBudgetResetInfo() -> [(index: Int, date: Date, label: String)] {
        guard let budget = budget else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        let adjustedToday = calendar.date(byAdding: .weekOfYear, value: -periodOffset, to: today) ?? today
        
        var resetPoints: [(index: Int, date: Date, label: String)] = []
        
        switch selectedPeriod {
        case .daily:
            // Daily view: Show reset lines for weekly, monthly, yearly budgets
            switch budget.period {
            case .daily:
                // Don't show - each point is already a budget period
                break
            case .weekly:
                // Show Sunday resets
                for i in 0..<7 {
                    let date = calendar.date(byAdding: .day, value: -i, to: adjustedToday) ?? adjustedToday
                    if calendar.component(.weekday, from: date) == 1 { // Sunday
                        let index = 6 - i
                        if index >= 0 && index < data.count {
                            resetPoints.append((index: index, date: date, label: "Weekly"))
                        }
                    }
                }
            case .monthly:
                // Show monthly resets (1st of month)
                for i in 0..<7 {
                    let date = calendar.date(byAdding: .day, value: -i, to: adjustedToday) ?? adjustedToday
                    if calendar.component(.day, from: date) == 1 { // 1st of month
                        let index = 6 - i
                        if index >= 0 && index < data.count {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM"
                            resetPoints.append((index: index, date: date, label: formatter.string(from: date)))
                        }
                    }
                }
            case .yearly:
                // Show yearly resets (Jan 1st)
                for i in 0..<7 {
                    let date = calendar.date(byAdding: .day, value: -i, to: adjustedToday) ?? adjustedToday
                    if calendar.component(.month, from: date) == 1 && calendar.component(.day, from: date) == 1 {
                        let index = 6 - i
                        if index >= 0 && index < data.count {
                            resetPoints.append((index: index, date: date, label: "New Year"))
                        }
                    }
                }
            }
            
        case .weekly:
            // Weekly view: Show reset lines for monthly, yearly budgets
            switch budget.period {
            case .daily, .weekly:
                // Don't show - each point is already a budget period or smaller
                break
            case .monthly:
                // Show monthly resets - find which weeks contain the 1st of month
                let adjustedStartDate = calendar.date(byAdding: .weekOfYear, value: -periodOffset * 5, to: today) ?? today
                let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: adjustedStartDate) ?? DateInterval(start: adjustedStartDate, duration: TimeInterval(7*24*60*60))
                let currentWeekStart = currentWeekInterval.start
                
                for weekIndex in 0..<5 {
                    let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekIndex, to: currentWeekStart) ?? currentWeekStart
                    let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                    
                    // Check if this week contains the 1st of any month
                    var currentDate = weekStart
                    while currentDate <= weekEnd {
                        if calendar.component(.day, from: currentDate) == 1 {
                            let index = 4 - weekIndex // Reverse index
                            if index >= 0 && index < data.count {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MMM"
                                resetPoints.append((index: index, date: currentDate, label: formatter.string(from: currentDate)))
                                break
                            }
                        }
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                }
            case .yearly:
                // Show yearly resets - find which weeks contain Jan 1st
                let adjustedStartDate = calendar.date(byAdding: .weekOfYear, value: -periodOffset * 5, to: today) ?? today
                let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: adjustedStartDate) ?? DateInterval(start: adjustedStartDate, duration: TimeInterval(7*24*60*60))
                let currentWeekStart = currentWeekInterval.start
                
                for weekIndex in 0..<5 {
                    let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekIndex, to: currentWeekStart) ?? currentWeekStart
                    let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                    
                    // Check if this week contains Jan 1st
                    var currentDate = weekStart
                    while currentDate <= weekEnd {
                        if calendar.component(.month, from: currentDate) == 1 && calendar.component(.day, from: currentDate) == 1 {
                            let index = 4 - weekIndex // Reverse index
                            if index >= 0 && index < data.count {
                                resetPoints.append((index: index, date: currentDate, label: "New Year"))
                                break
                            }
                        }
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                }
            }
            
        case .monthly:
            // Monthly view: Show reset lines for yearly budgets only
            switch budget.period {
            case .daily, .weekly, .monthly:
                // Don't show - each point is already a budget period or smaller
                break
            case .yearly:
                // Show yearly resets (January)
                for i in 0..<6 {
                    let adjustedStartDate = calendar.date(byAdding: .month, value: -periodOffset * 6, to: today) ?? today
                    let date = calendar.date(byAdding: .month, value: -i, to: adjustedStartDate) ?? adjustedStartDate
                    if calendar.component(.month, from: date) == 1 { // January
                        let index = 5 - i // Reverse index
                        if index >= 0 && index < data.count {
                            resetPoints.append((index: index, date: date, label: "New Year"))
                        }
                    }
                }
            }
        }
        
        return resetPoints
    }
    
    
}

// Custom speech bubble shape
struct SpeechBubbleShape: Shape {
    let tailPointsUp: Bool
    
    init(tailPointsUp: Bool = false) {
        self.tailPointsUp = tailPointsUp
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 8
        let tailWidth: CGFloat = 12
        let tailHeight: CGFloat = 8
        
        if tailPointsUp {
            // Tail points up - bubble is below the point
            // Start from top-left corner (after tail area)
            path.move(to: CGPoint(x: cornerRadius, y: tailHeight))
            
            // Top edge to tail start
            path.addLine(to: CGPoint(x: rect.width/2 - tailWidth/2, y: tailHeight))
            
            // Tail (pointing up)
            path.addLine(to: CGPoint(x: rect.width/2, y: 0))
            path.addLine(to: CGPoint(x: rect.width/2 + tailWidth/2, y: tailHeight))
            
            // Continue top edge
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: tailHeight))
            
            // Top-right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: tailHeight + cornerRadius),
                control: CGPoint(x: rect.width, y: tailHeight)
            )
            
            // Right edge
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
            
            // Bottom-right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
                control: CGPoint(x: rect.width, y: rect.height)
            )
            
            // Bottom edge
            path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
            
            // Bottom-left corner
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - cornerRadius),
                control: CGPoint(x: 0, y: rect.height)
            )
            
            // Left edge
            path.addLine(to: CGPoint(x: 0, y: tailHeight + cornerRadius))
            
            // Top-left corner
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: tailHeight),
                control: CGPoint(x: 0, y: tailHeight)
            )
            
        } else {
            // Tail points down - bubble is above the point (original logic)
            // Start from top-left corner
            path.move(to: CGPoint(x: cornerRadius, y: 0))
            
            // Top edge
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
            
            // Top-right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: cornerRadius),
                control: CGPoint(x: rect.width, y: 0)
            )
            
            // Right edge
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - tailHeight - cornerRadius))
            
            // Bottom-right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.width - cornerRadius, y: rect.height - tailHeight),
                control: CGPoint(x: rect.width, y: rect.height - tailHeight)
            )
            
            // Bottom edge to tail start
            path.addLine(to: CGPoint(x: rect.width/2 + tailWidth/2, y: rect.height - tailHeight))
            
            // Tail (pointing down)
            path.addLine(to: CGPoint(x: rect.width/2, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width/2 - tailWidth/2, y: rect.height - tailHeight))
            
            // Continue bottom edge
            path.addLine(to: CGPoint(x: cornerRadius, y: rect.height - tailHeight))
            
            // Bottom-left corner
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - tailHeight - cornerRadius),
                control: CGPoint(x: 0, y: rect.height - tailHeight)
            )
            
            // Left edge
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            
            // Top-left corner
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: 0),
                control: CGPoint(x: 0, y: 0)
            )
        }
        
        return path
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    static let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"  // Show start of week
        return formatter
    }()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"  // Show month abbreviation (Jan, Feb, etc.)
        return formatter
    }()
}

#if DEBUG
struct SpendingGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        let calendar = Calendar.current
        
        // Add sample expenses
        dataManager.expenses = [
            Expense(amount: 25.0, note: "Lunch", date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date(), category: .food),
            Expense(amount: 15.0, note: "Coffee", date: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date(), category: .food),
            Expense(amount: 50.0, note: "Groceries", date: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date(), category: .food)
        ]
        
        return SpendingGraphView(dataManager: dataManager)
    }
}
#endif