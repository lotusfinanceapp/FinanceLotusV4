import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var showElements = false
    @State private var selectedHistoryPeriod: BudgetPeriod? = nil
    @State private var selectedDateRange: DateRange? = nil
    @State private var selectedPeriodForDetail: HistoricalPeriod? = nil
    
    // For now, we'll simulate historical periods
    // In the future, this could come from actual budget history storage
    private var historicalPeriods: [HistoricalPeriod] {
        guard let currentBudget = dataManager.budget else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        var periods: [HistoricalPeriod] = []
        
        // Generate historical periods based on current budget type
        switch currentBudget.period {
        case .daily:
            // Show last 7 days
            for i in 1...7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                    let startDate = calendar.startOfDay(for: date)
                    let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                    periods.append(HistoricalPeriod(
                        id: UUID(),
                        budgetAmount: currentBudget.amount,
                        period: .daily,
                        startDate: startDate,
                        endDate: endDate,
                        displayName: DateFormatter.dayOnlyFormatter.string(from: date)
                    ))
                }
            }
        case .weekly:
            // Show last 4 weeks
            for i in 1...4 {
                if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                   let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) {
                    periods.append(HistoricalPeriod(
                        id: UUID(),
                        budgetAmount: currentBudget.amount,
                        period: .weekly,
                        startDate: weekInterval.start,
                        endDate: weekInterval.end,
                        displayName: "Week of \(DateFormatter.shortDateFormatter.string(from: weekInterval.start))"
                    ))
                }
            }
        case .monthly:
            // Show last 6 months
            for i in 1...6 {
                if let date = calendar.date(byAdding: .month, value: -i, to: now),
                   let monthInterval = calendar.dateInterval(of: .month, for: date) {
                    periods.append(HistoricalPeriod(
                        id: UUID(),
                        budgetAmount: currentBudget.amount,
                        period: .monthly,
                        startDate: monthInterval.start,
                        endDate: monthInterval.end,
                        displayName: DateFormatter.monthYearFormatter.string(from: date)
                    ))
                }
            }
        case .yearly:
            // Show last 3 years
            for i in 1...3 {
                if let date = calendar.date(byAdding: .year, value: -i, to: now),
                   let yearInterval = calendar.dateInterval(of: .year, for: date) {
                    periods.append(HistoricalPeriod(
                        id: UUID(),
                        budgetAmount: currentBudget.amount,
                        period: .yearly,
                        startDate: yearInterval.start,
                        endDate: yearInterval.end,
                        displayName: DateFormatter.yearFormatter.string(from: date)
                    ))
                }
            }
        }
        
        return periods
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // === HEADER ===
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.colAccent)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5), value: showElements)
                    
                    Text("Budget History")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                    
                    Text("Review your past spending periods")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                }
                .padding(.top, 100) // Account for header
                
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
                    LazyVStack(spacing: 16) {
                        ForEach(Array(historicalPeriods.enumerated()), id: \.element.id) { index, period in
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
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Account for tab bar
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
        .sheet(item: $selectedPeriodForDetail) { period in
            let dateRange = DateRange(
                start: period.startDate,
                end: period.endDate,
                displayName: period.displayName
            )
            CategoryDetailView(
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
                    .frame(width: CGFloat(progressPercentage / 100) * (UIScreen.main.bounds.width - 80), height: 6)
            }
            
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