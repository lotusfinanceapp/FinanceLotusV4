import SwiftUI

// MARK: - Date Range Model
struct DateRange {
    let start: Date
    let end: Date
    let displayName: String
}

// MARK: - Category Detail View - DETAILED BREAKDOWN OF SELECTED CATEGORY
struct CategoryDetailView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var selectedCategory: CustomCategory?
    @State private var showElements = false
    @State private var circleRotation: Double = 0
    @State private var circleScale: Double = 1.0
    @State private var selectedExpenseForDetail: Expense? = nil
    @Environment(\.presentationMode) var presentationMode
    
    // Optional date range for historical periods
    let dateRange: DateRange?
    let historicalBudget: Double?
    
    init(dataManager: BudgetDataManager, initialCategory: CustomCategory?, dateRange: DateRange? = nil, historicalBudget: Double? = nil) {
        self.dataManager = dataManager
        self._selectedCategory = State(initialValue: initialCategory)
        self.dateRange = dateRange
        self.historicalBudget = historicalBudget
    }
    
    // Get filtered expenses based on date range or current period
    private var filteredExpenses: [Expense] {
        if let dateRange = dateRange {
            // Historical period - filter by date range
            return dataManager.expenses.filter { expense in
                expense.date >= dateRange.start && expense.date < dateRange.end
            }
        } else {
            // Current period - use existing logic
            return dataManager.currentPeriodExpenses
        }
    }
    
    // Get budget amount (historical or current)
    private var budgetAmount: Double {
        return historicalBudget ?? dataManager.budget?.amount ?? 0
    }
    
    // Calculate total spent for this period
    private var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    // Get appropriate title for the period
    private var periodTitle: String {
        if let dateRange = dateRange {
            // Historical period - use relative names
            let calendar = Calendar.current
            let now = Date()

            // Check if it's from this month, last month, etc.
            if calendar.isDate(dateRange.start, equalTo: now, toGranularity: .month) {
                return "This Month"
            } else if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                      calendar.isDate(dateRange.start, equalTo: lastMonth, toGranularity: .month) {
                return "Last Month"
            } else {
                // Use the displayName for older periods (e.g., "August 2024")
                return dateRange.displayName
            }
        } else {
            // Current period
            guard let budget = dataManager.budget else { return "This Period" }
            switch budget.period {
            case .daily: return "Today"
            case .weekly: return "This Week"
            case .monthly: return "This Month"
            case .yearly: return "This Year"
            }
        }
    }
    
    // Calculate rotation needed to center selected category at bottom (270 degrees)
    private func calculateRotationForCategory(_ targetCategory: CustomCategory) -> Double {
        guard !filteredExpenses.isEmpty else { return 0 }
        
        let categoryExpenses = Dictionary(grouping: filteredExpenses) { $0.effectiveCategory }
        let sortedCategories = categoryExpenses.keys.sorted { category1, category2 in
            let total1 = categoryExpenses[category1]?.reduce(0) { $0 + $1.amount } ?? 0
            let total2 = categoryExpenses[category2]?.reduce(0) { $0 + $1.amount } ?? 0
            return total1 > total2
        }
        
        
        var currentPosition: Double = 0
        for category in sortedCategories {
            let categoryTotal = categoryExpenses[category]?.reduce(0) { $0 + $1.amount } ?? 0
            let segmentPercentage = totalSpent > 0 ? categoryTotal / totalSpent : 0
            let segmentCenter = currentPosition + (segmentPercentage / 2)
            
            if category.id == targetCategory.id {
                // Convert to degrees and rotate so segment center is at bottom (180°)
                let targetAngle = segmentCenter * 360
                return 180 - targetAngle
            }
            
            currentPosition += segmentPercentage
        }
        
        return 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // === BACK BUTTON HEADER WITH TITLE ===
            ZStack {
                // Centered title
                HStack {
                    Spacer()
                    Text(periodTitle)
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
                LazyVStack(spacing: 20) {
                    // === TOP SPACING ===
                    Color.clear.frame(height: 10)
                    
                    // === BUDGET PROGRESS BAR ===
                    if let budget = dataManager.budget {
                        VStack(spacing: 8) {
                            // "Budget Progress" label above the bar - centered
                            Text("Budget Progress")
                                .font(.subheadline)
                                .foregroundColor(.colSecondaryText)
                            
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.colProgressTrack.opacity(0.3))
                                    .frame(height: 8)
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: totalSpent > budgetAmount ? 
                                                [Color.red.opacity(0.8), Color.red] : 
                                                [Color.colProgressFill1, Color.colProgressFill2]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: showElements ? min(CGFloat(totalSpent / budgetAmount), 1.0) * 240 : 0, height: 8)
                                    .animation(.easeOut(duration: 0.8).delay(0.4), value: showElements)
                            }
                            .frame(width: 240)
                            
                            // Amount text below the bar - shows overspent or remaining
                            Text(totalSpent > budgetAmount ? 
                                 "Overspent: \((totalSpent - budgetAmount).formattedCurrency())" :
                                 "Remaining: \((budgetAmount - totalSpent).formattedCurrency())")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(totalSpent > budgetAmount ? .red : .colPrimaryText)
                                .opacity(showElements ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.4), value: showElements)
                        }
                        .padding(.horizontal, 20)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    }
                    
                    // Add more spacing before the circle
                    Color.clear.frame(height: 30)
                    
                    // === ZOOMED PROGRESS CIRCLE ===
                    if let budget = dataManager.budget {
                        let categoryExpenses = Dictionary(grouping: filteredExpenses) { $0.effectiveCategory }
                        let sortedCategories = categoryExpenses.keys.sorted { category1, category2 in
                            let total1 = categoryExpenses[category1]?.reduce(0) { $0 + $1.amount } ?? 0
                            let total2 = categoryExpenses[category2]?.reduce(0) { $0 + $1.amount } ?? 0
                            return total1 > total2
                        }
                        
                                        
                        let segments = sortedCategories.enumerated().map { index, category -> (CustomCategory, Double, Double) in
                            let categoryTotal = categoryExpenses[category]?.reduce(0) { $0 + $1.amount } ?? 0
                            let segmentPercentage = totalSpent > 0 ? categoryTotal / totalSpent : 0
                            
                            let startPosition = sortedCategories.prefix(index).reduce(0.0) { result, prevCategory in
                                let prevTotal = categoryExpenses[prevCategory]?.reduce(0) { $0 + $1.amount } ?? 0
                                return result + (totalSpent > 0 ? prevTotal / totalSpent : 0)
                            }
                            
                            return (category, startPosition, startPosition + segmentPercentage)
                        }
                        
                        ZStack {
                            // Background circle track (clickable to go back to budget overview)
                            Circle()
                                .stroke(Color.colProgressTrack, lineWidth: 60)
                                .opacity(showElements ? 1.0 : 0.0)
                                .scaleEffect(showElements ? 1.0 : 0.8)
                                .rotationEffect(.degrees(-90 + circleRotation))
                                .animation(.easeOut(duration: 0.6), value: showElements)
                                .animation(.easeOut(duration: 0.8), value: circleRotation)
                                .onTapGesture {
                                    // Reset to budget overview (clear selected category)
                                    selectedCategory = nil
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        circleRotation = 0
                                    }
                                    
                                    // Expansion animation
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        circleScale = 1.03
                                    }
                                    
                                    // Return to normal after delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            circleScale = 1.0
                                        }
                                    }
                                }
                            
                            // Category segments
                            ForEach(segments.indices, id: \.self) { index in
                                let (category, startPos, endPos) = segments[index]
                                
                                Circle()
                                    .trim(from: startPos, to: showElements ? endPos : startPos)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                category.color.opacity(0.6),
                                                category.color,
                                                category.color.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: selectedCategory?.id == category.id ? 55 : 45, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90 + circleRotation))
                                    .animation(.easeOut(duration: 0.8), value: showElements)
                                    .animation(.easeOut(duration: 0.8), value: circleRotation)
                                    .onTapGesture {
                                        selectedCategory = category
                                        withAnimation(.easeInOut(duration: 0.8)) {
                                            circleRotation = calculateRotationForCategory(category)
                                        }
                                        
                                        // Expansion animation
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            circleScale = 1.03
                                        }
                                        
                                        // Return to normal after delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                circleScale = 1.0
                                            }
                                        }
                                    }
                            }
                            
                            // Amount spent text in center (clickable to reset to budget overview)
                            Button(action: {
                                selectedCategory = nil
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    circleRotation = 0
                                }
                                
                                // Expansion animation
                                withAnimation(.easeOut(duration: 0.1)) {
                                    circleScale = 1.03
                                }
                                
                                // Return to normal after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        circleScale = 1.0
                                    }
                                }
                            }) {
                                Text(totalSpent.formattedCurrency())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                                    .opacity(showElements ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.5).delay(0.8), value: showElements)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(width: 280, height: 280) // Larger circle
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: 0.15), value: circleScale)
                    }
                    
                    // === CONNECTION LINE AND DETAILS CARD ===
                    if let budget = dataManager.budget {
                        ZStack {
                            // Empty state card (when no category selected)
                            VStack(spacing: 20) {
                                // Connection line
                                Rectangle()
                                    .fill(Color.colAccent.opacity(0.6))
                                    .frame(width: 3, height: 40)
                                    .opacity(showElements ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.5).delay(1.0), value: showElements)
                                    .animation(.easeInOut(duration: 0.8), value: selectedCategory)
                                
                                // Empty state card
                                VStack(alignment: .center, spacing: 20) {
                                    VStack(spacing: 15) {
                                        Image(systemName: "chart.pie")
                                            .font(.largeTitle)
                                            .foregroundColor(.colPieChartIcon)
                                        
                                        Text("Budget Overview")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.colPrimaryText)
                                        
                                        Text("Tap on any colored segment above to view detailed breakdown for that expense category")
                                            .font(.body)
                                            .foregroundColor(.colSecondaryText)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.colCardBackground)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                )
                                .opacity(showElements ? 1.0 : 0.0)
                                .offset(y: showElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(1.2), value: showElements)
                                .animation(.easeInOut(duration: 0.8), value: selectedCategory)
                            }
                            .opacity(selectedCategory == nil ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8), value: selectedCategory)
                            
                            // Category detail card (when category is selected)
                            Group {
                                if let selectedCategory = selectedCategory {
                                    let categoryExpenses = filteredExpenses.filter { $0.effectiveCategory.id == selectedCategory.id }
                                    let categoryTotal = categoryExpenses.reduce(0) { $0 + $1.amount }
                                    let categoryPercentage = totalSpent > 0 ? (categoryTotal / totalSpent) * 100 : 0
                                    
                                    VStack(spacing: 20) {
                                        // Connection line
                                        Rectangle()
                                            .fill(selectedCategory.color.opacity(0.6))
                                            .frame(width: 3, height: 40)
                                            .opacity(showElements ? 1.0 : 0.0)
                                            .animation(.easeOut(duration: 0.5).delay(1.0), value: showElements)
                                    
                                        // Details card
                                        VStack(alignment: .leading, spacing: 20) {
                                        // Category header
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedCategory.icon)
                                                .font(.title)
                                                .foregroundColor(selectedCategory.color)
                                                .frame(width: 32, height: 32)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(selectedCategory.name)
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                
                                                Text("Category Overview")
                                                    .font(.caption)
                                                    .foregroundColor(.colSecondaryText)
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        // Category statistics
                                        VStack(spacing: 15) {
                                            HStack {
                                                Text("Total Spent:")
                                                    .font(.headline)
                                                    .foregroundColor(.colSecondaryText)
                                                Spacer()
                                                Text(categoryTotal.formattedCurrency())
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(selectedCategory.color)
                                            }
                                            
                                            HStack {
                                                Text("Percentage of Total:")
                                                    .font(.headline)
                                                    .foregroundColor(.colSecondaryText)
                                                Spacer()
                                                Text(String(format: "%.1f%%", categoryPercentage))
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(selectedCategory.color)
                                            }
                                            
                                            HStack {
                                                Text("Transactions:")
                                                    .font(.headline)
                                                    .foregroundColor(.colSecondaryText)
                                                Spacer()
                                                Text("\(categoryExpenses.count)")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(selectedCategory.color)
                                            }
                                        }
                                        
                                        // Individual transactions
                                        if !categoryExpenses.isEmpty {
                                            Divider()
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Recent Transactions")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                
                                                ForEach(categoryExpenses.sorted(by: { $0.date > $1.date }).prefix(5), id: \.id) { expense in
                                                    HStack {
                                                        Text({
                                                            let text = expense.note.isEmpty ? "No description" : expense.note
                                                            return text.count > 11 ? String(text.prefix(11)) + "..." : text
                                                        }())
                                                            .font(.body)
                                                            .foregroundColor(.colSecondaryText)
                                                        
                                                        Spacer()
                                                        
                                                        Text(expense.date, style: .date)
                                                            .font(.body)
                                                            .foregroundColor(.colSecondaryText)
                                                            .multilineTextAlignment(.trailing)
                                                    }
                                                    .padding(.vertical, 4)
                                                    .onTapGesture {
                                                        selectedExpenseForDetail = expense
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.colCardBackground)
                                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.colCardBackground.opacity(0.7), lineWidth: 2)
                                    )
                                    .opacity(showElements ? 1.0 : 0.0)
                                    .offset(y: showElements ? 0 : 20)
                                    .animation(.easeOut(duration: 0.6).delay(1.2), value: showElements)
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                            .opacity(selectedCategory != nil ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8), value: selectedCategory)
                        }
                    }
                    
                    // === STATS SECTION ===
                    if !dataManager.expenses.isEmpty {
                        StatsSection(dataManager: dataManager, expenses: filteredExpenses, totalSpent: totalSpent)
                            .opacity(showElements ? 1.0 : 0.0)
                            .offset(y: showElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(1.4), value: showElements)
                            .opacity(selectedCategory == nil ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8), value: selectedCategory)
                    }
                    
                    // Add bottom padding for safe scrolling
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal)
            }
            .onAppear {
                showElements = false
                if let selectedCategory = selectedCategory {
                    circleRotation = calculateRotationForCategory(selectedCategory)
                }
                withAnimation {
                    showElements = true
                }
            }
            .onDisappear {
                showElements = false
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .sheet(item: $selectedExpenseForDetail) { expense in
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                ExpenseDetailView(dataManager: dataManager, expense: expense)
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
    struct CategoryDetailView_Previews: PreviewProvider {
        static var previews: some View {
            let dataManager = BudgetDataManager()
            dataManager.budget = Budget(amount: 100.0, period: .monthly, dateCreated: Date())
            dataManager.expenses = [
                Expense(amount: 25.0, note: "Lunch", date: Date(), category: .food),
                Expense(amount: 15.0, note: "Coffee", date: Date(), category: .food),
                Expense(amount: 30.0, note: "Uber", date: Date(), category: .transport),
                Expense(amount: 12.0, note: "Movie ticket", date: Date(), category: .entertainment)
            ]
            let sampleCategory = CustomCategory(name: "Food & Dining", icon: "fork.knife", colorHex: "#FF6B6B", isDefault: true)
            return CategoryDetailView(dataManager: dataManager, initialCategory: sampleCategory)
                .previewDisplayName("Category Detail Screen")
        }
    }
#endif

// MARK: - Stats Section
struct StatsSection: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var selectedCardID: String? = nil
    let expenses: [Expense]
    let totalSpent: Double
    
    var mostSpentCategory: (category: CustomCategory, amount: Double)? {
        guard !expenses.isEmpty else { return nil }
        
        let categoryTotals = Dictionary(grouping: expenses) { $0.effectiveCategory }
            .mapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }
        
        return categoryTotals.max { $0.value < $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }
    
    var lastTransaction: Expense? {
        expenses.max { $0.date < $1.date }
    }
    
    var averageDailySpending: Double {
        guard !expenses.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let daysSinceStart = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 1
        
        return totalSpent / Double(max(daysSinceStart, 1))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Stats header
            HStack {
                Text("Quick Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            // Stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                
                // Most spent category
                if let mostSpent = mostSpentCategory {
                    UnifiedStatCard(
                        title: "Most Spent",
                        value: mostSpent.amount.formattedCurrency(),
                        subtitle: mostSpent.category.name,
                        icon: mostSpent.category.icon,
                        color: mostSpent.category.color,
                        isSelected: selectedCardID == "most_spent",
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedCardID = selectedCardID == "most_spent" ? nil : "most_spent"
                            }
                        }
                    )
                }

                // Last expense
                if let lastTx = lastTransaction {
                    UnifiedStatCard(
                        title: "Last Expense",
                        value: lastTx.amount.formattedCurrency(),
                        subtitle: {
                            let text = lastTx.note.isEmpty ? "No description" : lastTx.note
                            return text.count > 15 ? String(text.prefix(15)) + "..." : text
                        }(),
                        icon: lastTx.effectiveCategory.icon,
                        color: lastTx.effectiveCategory.color,
                        isSelected: selectedCardID == "last_transaction",
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedCardID = selectedCardID == "last_transaction" ? nil : "last_transaction"
                            }
                        }
                    )
                }

                // Average daily spending
                UnifiedStatCard(
                    title: "Daily Average",
                    value: String(format: "$%.0f", averageDailySpending),
                    subtitle: "This month",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .colAccent,
                    isSelected: selectedCardID == "daily_average",
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCardID = selectedCardID == "daily_average" ? nil : "daily_average"
                        }
                    }
                )

                // Total transactions count
                UnifiedStatCard(
                    title: "Transactions",
                    value: "\(expenses.count)",
                    subtitle: "This period",
                    icon: "list.bullet",
                    color: .blue,
                    isSelected: selectedCardID == "transactions",
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCardID = selectedCardID == "transactions" ? nil : "transactions"
                        }
                    }
                )
            }


        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

