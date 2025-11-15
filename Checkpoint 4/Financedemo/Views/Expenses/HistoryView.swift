import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var showElements = false
    @State private var selectedHistoryPeriod: BudgetPeriod? = nil
    @State private var selectedDateRange: DateRange? = nil
    @State private var selectedPeriodForDetail: HistoricalPeriod? = nil
    @AppStorage("selectedBudgetSort") private var selectedSort: BudgetSortOption = .date
    @State private var showingSortPicker = false
    @State private var loadedBatches = 0 // Number of 6-period batches loaded after the initial 12

    enum BudgetSortOption: String, CaseIterable {
        case date = "Date"
        case budgetAmount = "Budget $"
        case spentAmount = "Spent $"

        var icon: String {
            switch self {
            case .date: return "calendar"
            case .budgetAmount: return "dollarsign.circle"
            case .spentAmount: return "chart.bar"
            }
        }
    }
    
    // Generate historical periods with their respective budgets
    private var historicalPeriods: [HistoricalPeriod] {
        guard let currentBudget = dataManager.budget else { return [] }

        let calendar = Calendar.current
        let now = Date()
        var periods: [HistoricalPeriod] = []

        // Generate historical periods based on current budget type
        switch currentBudget.period {
        case .daily:
            // Show last 7 days (only if they have a budget entry)
            for i in 1...7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                    let startDate = calendar.startOfDay(for: date)
                    let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                    // Get budget for this specific day
                    let budgetForDay = dataManager.getBudget(for: date)
                    // Only include days that have an actual budget entry
                    if let budget = budgetForDay {
                        periods.append(HistoricalPeriod(
                            id: UUID(),
                            budgetAmount: budget.amount,
                            period: .daily,
                            startDate: startDate,
                            endDate: endDate,
                            displayName: DateFormatter.dayOnlyFormatter.string(from: date)
                        ))
                    }
                }
            }
        case .weekly:
            // Show last 4 weeks (only if they have a budget entry)
            for i in 1...4 {
                if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                   let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) {
                    // Get budget for this specific week
                    let budgetForWeek = dataManager.getBudget(for: date)
                    // Only include weeks that have an actual budget entry
                    if let budget = budgetForWeek {
                        periods.append(HistoricalPeriod(
                            id: UUID(),
                            budgetAmount: budget.amount,
                            period: .weekly,
                            startDate: weekInterval.start,
                            endDate: weekInterval.end,
                            displayName: "Week of \(DateFormatter.shortDateFormatter.string(from: weekInterval.start))"
                        ))
                    }
                }
            }
        case .monthly:
            // Show last 6 months (only if they have a budget entry)
            for i in 1...6 {
                if let date = calendar.date(byAdding: .month, value: -i, to: now),
                   let monthInterval = calendar.dateInterval(of: .month, for: date) {
                    // Get budget for this specific month
                    let budgetForMonth = dataManager.getBudget(for: date)
                    // Only include months that have an actual budget entry
                    if let budget = budgetForMonth {
                        periods.append(HistoricalPeriod(
                            id: UUID(),
                            budgetAmount: budget.amount,
                            period: .monthly,
                            startDate: monthInterval.start,
                            endDate: monthInterval.end,
                            displayName: DateFormatter.monthYearFormatter.string(from: date)
                        ))
                    }
                }
            }
        case .yearly:
            // Show last 3 years (only if they have a budget entry)
            for i in 1...3 {
                if let date = calendar.date(byAdding: .year, value: -i, to: now),
                   let yearInterval = calendar.dateInterval(of: .year, for: date) {
                    // Get budget for this specific year
                    let budgetForYear = dataManager.getBudget(for: date)
                    // Only include years that have an actual budget entry
                    if let budget = budgetForYear {
                        periods.append(HistoricalPeriod(
                            id: UUID(),
                            budgetAmount: budget.amount,
                            period: .yearly,
                            startDate: yearInterval.start,
                            endDate: yearInterval.end,
                            displayName: DateFormatter.yearFormatter.string(from: date)
                        ))
                    }
                }
            }
        }

        return sortedPeriods(periods)
    }

    // Sort periods based on selected sort option
    private func sortedPeriods(_ periods: [HistoricalPeriod]) -> [HistoricalPeriod] {
        switch selectedSort {
        case .date:
            // Newest to oldest (descending by start date)
            return periods.sorted { $0.startDate > $1.startDate }
        case .budgetAmount:
            // Highest to lowest budget amount (descending)
            return periods.sorted { $0.budgetAmount > $1.budgetAmount }
        case .spentAmount:
            // Highest to lowest spent amount (descending)
            return periods.sorted { amount(for: $0) > amount(for: $1) }
        }
    }

    // Helper to calculate total spent for a period
    private func amount(for period: HistoricalPeriod) -> Double {
        return getExpensesForPeriod(period).reduce(0) { $0 + $1.amount }
    }

    // Compute displayed periods with pagination (12 initially, then 6 per batch)
    private var displayedPeriods: [HistoricalPeriod] {
        let totalToShow = 12 + (loadedBatches * 6)
        return Array(historicalPeriods.prefix(totalToShow))
    }

    // Check if there are more periods to load
    private var hasMorePeriods: Bool {
        displayedPeriods.count < historicalPeriods.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // === HEADER ===
                VStack(spacing: 20) {
                    Text("Budget History")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.colSecondaryText)
                        .textCase(.uppercase)
                        .tracking(1)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4), value: showElements)
                }
                .padding(.top, 100) // Account for header

                // === DIVIDER ===
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showElements)

                // === SORT BUTTON ===
                Button(action: {
                    showingSortPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundColor(.colAccent)

                        Text(selectedSort.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.colAccent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(showElements ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: showElements)

                // === HISTORICAL PERIODS LIST ===
                if historicalPeriods.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(.colSecondaryText.opacity(0.6))
                        
                        Text("No History Yet")
                            .font(.headline)
                            .foregroundColor(.colPrimaryText)
                        
                        Text("Start tracking your budget to see historical data here")
                            .font(.subheadline)
                            .foregroundColor(.colSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                } else {
                    VStack(spacing: 16) {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(displayedPeriods.enumerated()), id: \.element.id) { index, period in
                                HistoricalPeriodCard(
                                    period: period,
                                    expenses: getExpensesForPeriod(period),
                                    dataManager: dataManager
                                )
                                .opacity(showElements ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.5).delay(0.3 + Double(index) * 0.1), value: showElements)
                                .onTapGesture {
                                    // Set the selected period - sheet will show automatically
                                    selectedPeriodForDetail = period
                                }
                            }
                        }

                        // See More button
                        if hasMorePeriods {
                            Button(action: {
                                withAnimation {
                                    loadedBatches += 1
                                }
                            }) {
                                HStack {
                                    Text("See More")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colAccent)

                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.colAccent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.colCardBackground)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, UIScreen.main.bounds.height < 700 ? 100 : 80) // Account for tab bar and navbar text
        }
        .background(Color.colBackground.ignoresSafeArea())
        .onAppear {
            showElements = false
            // Ensure state is properly reset when view appears
            selectedPeriodForDetail = nil

            withAnimation {
                showElements = true
            }
        }
        .onDisappear {
            showElements = false
        }
        .sheet(isPresented: $showingSortPicker) {
            BudgetSortPickerView(
                selectedSort: $selectedSort,
                isPresented: $showingSortPicker
            )
        }
        .fullScreenCover(item: $selectedPeriodForDetail) { period in
            let dateRange = DateRange(
                start: period.startDate,
                end: period.endDate,
                displayName: period.displayName
            )
            CircleExpansionView(
                dataManager: dataManager,
                initialCategory: nil,
                dateRange: dateRange,
                historicalBudget: period.budgetAmount
            )
        }
    }
    
    // Get expenses for a specific historical period
    private func getExpensesForPeriod(_ period: HistoricalPeriod) -> [Expense] {
        return dataManager.expenses.filter { expense in
            expense.date >= period.startDate && expense.date < period.endDate
        }
    }
}

// MARK: - Historical Period Model
struct HistoricalPeriod: Identifiable {
    let id: UUID
    let budgetAmount: Double
    let period: BudgetPeriod
    let startDate: Date
    let endDate: Date
    let displayName: String
}

// MARK: - Historical Period Card
struct HistoricalPeriodCard: View {
    let period: HistoricalPeriod
    let expenses: [Expense]
    let dataManager: BudgetDataManager
    @State private var animatedProgress: Double = 0

    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var progressPercentage: Double {
        guard period.budgetAmount > 0 else { return 0 }
        return min(100, (totalSpent / period.budgetAmount) * 100)
    }

    private var isOverBudget: Bool {
        totalSpent > period.budgetAmount
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                    
                    Text("\(period.period.rawValue) Budget")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(totalSpent.formattedCurrency())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isOverBudget ? .red : .colAccent)
                    
                    Text("of \(period.budgetAmount.formattedCurrency())")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.colProgressTrack.opacity(0.3))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isOverBudget ?
                                    [Color.red.opacity(0.8), Color.red] :
                                    [Color.colProgressFill1, Color.colProgressFill2]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(animatedProgress / 100) * geometry.size.width, height: 6)
                }
            }
            .frame(height: 6)
            
            // Stats row
            HStack(spacing: 20) {
                // Percentage
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f", progressPercentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isOverBudget ? .red : .colAccent)
                    
                    Text("Used")
                        .font(.caption2)
                        .foregroundColor(.colSecondaryText)
                }
                
                Spacer()
                
                // Transaction count
                VStack(spacing: 2) {
                    Text("\(expenses.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                    
                    Text("Transactions")
                        .font(.caption2)
                        .foregroundColor(.colSecondaryText)
                }
                
                Spacer()
                
                // Status
                VStack(spacing: 2) {
                    Text(isOverBudget ? "Over" : (progressPercentage > 90 ? "Close" : "Good"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isOverBudget ? .red : (progressPercentage > 90 ? .orange : .green))
                    
                    Text("Status")
                        .font(.caption2)
                        .foregroundColor(.colSecondaryText)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            // Animate progress bar from 0 to actual percentage
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = progressPercentage
            }
        }
    }
}


// MARK: - Date Formatters
extension DateFormatter {
    static let dayOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        // Add sample budget and expenses for preview
        dataManager.setBudget(1000, period: .monthly)
        
        return HistoryView(dataManager: dataManager)
    }
}
#endif