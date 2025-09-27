import SwiftUI

// MARK: - Progress Screen - BUDGET OVERVIEW AND STATISTICS
struct ProgressView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var showElements = false        // Controls entrance animations
    @State private var showingCategoryDetail = false
    @State private var selectedCategoryForDetail: CustomCategory? = nil
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var showingBudgetEdit = false
    @State private var showingSpendingView = false
    @State private var showingAllExpenses = false
    @State private var showingSpendingGraph = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                if let budget = dataManager.budget {
                    // === TOP SPACING ===
                    Color.clear.frame(height: 80) // Space for fixed logo
                
                // === HEADER SECTION ===
                VStack(spacing: 15) {
                    // Chart icon (edit color with colChartIcon)
                    Image(systemName: "house.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.colChartIcon)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)
                    
                    // Main heading
                    Text("Budget Overview")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                
                // === TODAY VIEW ===
                TodayView(dataManager: dataManager)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showElements)
                
                // === PROGRESS CIRCLE CARD ===
                VStack(spacing: 20) {
                    // Header with title on left and View Graph button on right
                    HStack {
                        Text({
                            switch budget.period {
                            case .daily: return "This Day"
                            case .weekly: return "This Week"
                            case .monthly: return "This Month"
                            case .yearly: return "This Year"
                            }
                        }())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)

                        Spacer()

                        Button(action: {
                            showingSpendingGraph = true
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.colAccent)
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)

                    // Budget info line above progress bar
                    HStack(spacing: 8) {
                        Text("Budget \(budget.amount.formattedCurrency())")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.colSecondaryText)

                        Circle()
                            .fill(Color.colSecondaryText)
                            .frame(width: 2, height: 2)

                        Text("Spent \(dataManager.totalSpent.formattedCurrency())")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.colSecondaryText)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: showElements)

                    // Budget progress bar
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.colProgressTrack.opacity(0.3))
                                .frame(height: 8)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: dataManager.totalSpent > budget.amount ?
                                            [Color.red.opacity(0.8), Color.red] :
                                            [Color.colProgressFill1, Color.colProgressFill2]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: showElements ? min(CGFloat(dataManager.totalSpent / budget.amount), 1.0) * 200 : 0, height: 8)
                                .animation(.easeOut(duration: 0.8).delay(0.5), value: showElements)
                        }
                        .frame(width: 200)

                        // Amount text below the bar - shows overspent or remaining
                        Text(dataManager.totalSpent > budget.amount ?
                             "Overspent: \((dataManager.totalSpent - budget.amount).formattedCurrency())" :
                             "Remaining: \((budget.amount - dataManager.totalSpent).formattedCurrency())")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(dataManager.totalSpent > budget.amount ? .red : .colPrimaryText)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: showElements)
                    }
                    .padding(.horizontal, 20)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)

                    // Add more spacing before the circle
                    Color.clear.frame(height: 20)
                    
                    // === PROGRESS CIRCLE WITH CATEGORY SEGMENTS ===
                    ZStack {
                        // Background circle track
                        Circle()
                            .stroke(Color.colProgressTrack, lineWidth: 50)
                            .opacity(showElements ? 1.0 : 0.0)
                            .scaleEffect(showElements ? 1.0 : 0.8)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                        
                        // Category-based progress segments
                        if let budget = dataManager.budget, !dataManager.currentPeriodExpenses.isEmpty {
                            let categoryExpenses = Dictionary(grouping: dataManager.currentPeriodExpenses) { $0.effectiveCategory }
                            let sortedCategories = categoryExpenses.keys.sorted { category1, category2 in
                                let total1 = categoryExpenses[category1]?.reduce(0) { $0 + $1.amount } ?? 0
                                let total2 = categoryExpenses[category2]?.reduce(0) { $0 + $1.amount } ?? 0
                                return total1 > total2
                            }
                            
                            let totalSpent = dataManager.totalSpent
                            
                            let segments = sortedCategories.enumerated().map { index, category -> (CustomCategory, Double, Double) in
                                let categoryTotal = categoryExpenses[category]?.reduce(0) { $0 + $1.amount } ?? 0
                                let segmentPercentage = totalSpent > 0 ? categoryTotal / totalSpent : 0
                                
                                let startPosition = sortedCategories.prefix(index).reduce(0.0) { result, prevCategory in
                                    let prevTotal = categoryExpenses[prevCategory]?.reduce(0) { $0 + $1.amount } ?? 0
                                    return result + (totalSpent > 0 ? prevTotal / totalSpent : 0)
                                }
                                
                                return (category, startPosition, startPosition + segmentPercentage)
                            }
                            
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
                                        style: StrokeStyle(lineWidth: 35, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeOut(duration: 0.8), value: showElements)
                                    .onTapGesture {
                                        selectedCategoryForDetail = category
                                        showingCategoryDetail = true
                                    }
                            }
                        }
                        
                        // Amount spent text in center
                        Text(dataManager.totalSpent.formattedCurrency())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.colPercentageText)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: showElements)
                    }
                    .frame(width: 185, height: 185) // Circle size

                    // Add more spacing after the circle
                    Color.clear.frame(height: 25)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.colCardBackground)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .opacity(showElements ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                .onTapGesture {
                    selectedCategoryForDetail = nil  // No specific category selected
                    showingCategoryDetail = true
                }
                    
                // === STATS CARDS SECTION WITH EXPLOSIVE ENTRANCE ===
                // Edit colors: colStatBudget, colStatSpent, colStatRemaining
                /* Remove these 3 for now
                 
                 VStack(spacing: 15) {
                    // Top row: Budget and Spent cards
                    HStack(spacing: 15) {
                        Button(action: {
                            showingBudgetEdit = true
                        }) {
                            StatCard(
                                title: "Budget",
                                value: budget.amount.formattedCurrency(),
                                color: .colStatBudget // Edit with colStatBudget
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(showElements ? 1.0 : 0.0)
                        .offset(y: showElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                        
                        Button(action: {
                            showingSpendingView = true
                        }) {
                            StatCard(
                                title: "Spent",
                                value: dataManager.totalSpent.formattedCurrency(),
                                color: .colStatSpent // Edit with colStatSpent
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(showElements ? 1.0 : 0.0)
                        .offset(y: showElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    }
                    
                    // Bottom row: Remaining card (full width)
                    StatCard(
                        title: "Remaining",
                        value: dataManager.remainingAmount.formattedCurrency(),
                        color: .colStatRemaining // Edit with colStatRemaining
                    )
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                }
                    */
                // === RECENT EXPENSES LIST (shows last 3 expenses) ===
                if !dataManager.expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Recent Expenses")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.colPrimaryText)
                            
                            Spacer()
                            
                            // Modern See All button
                            Button(action: {
                                showingAllExpenses = true
                            }) {
                                HStack(spacing: 6) {
                                    Text("See All")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: .colAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Group expenses by category for consistent styling
                        let recentExpenses = Array(dataManager.expenses.suffix(3).reversed())
                        let groupedExpenses = Dictionary(grouping: recentExpenses) { expense in
                            expense.effectiveCategory
                        }
                        
                        // Sort categories by total amount
                        let sortedCategories = Array(groupedExpenses.keys).sorted { category1, category2 in
                            let total1 = groupedExpenses[category1]?.reduce(0) { sum, expense in 
                                sum + expense.amount 
                            } ?? 0
                            let total2 = groupedExpenses[category2]?.reduce(0) { sum, expense in 
                                sum + expense.amount 
                            } ?? 0
                            return total1 > total2
                        }
                        
                        ForEach(sortedCategories, id: \.self) { category in
                            let categoryExpenses = groupedExpenses[category] ?? []
                            let categoryTotal = categoryExpenses.reduce(0) { sum, expense in 
                                sum + expense.amount 
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                // Category header with total
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .foregroundColor(category.color)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(category.name)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)
                                    
                                    Spacer()
                                    
                                    Text(categoryTotal.formattedCurrency())
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(category.color)
                                }
                                
                                // Individual expenses in this category
                                ForEach(categoryExpenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                                    HStack {
                                        Text({
                                            let text = expense.note.isEmpty ? "No note" : expense.note
                                            return text.count > 15 ? String(text.prefix(15)) + "..." : text
                                        }())
                                            .font(.body)
                                            .foregroundColor(.colSecondaryText)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("$\(expense.amount, specifier: "%.2f")")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.colPrimaryText)
                                            
                                            Text(expense.date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.colSecondaryText)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedCategoryForDetail = expense.effectiveCategory
                                        showingCategoryDetail = true
                                    }
                                }
                            }
                            .padding()
                            .background(Color.colCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.colCardBackground.opacity(0.7), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top)
                }
                    
                // === BUDGET EXCEEDED WARNING (only shows when budget is exceeded) ===
                if dataManager.remainingAmount <= 0 {
                    VStack(spacing: 10) {
                        // Warning text (edit color with colAlertText)
                        Text("⚠️ Budget Exceeded!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colAlertText)
                        
                        // Warning message
                        Text("You've spent your entire budget. Consider adjusting your spending or setting a new budget.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.colSecondaryText)
                    }
                    .padding()
                    .background(Color.colAlertBackground.opacity(0.3)) // Edit background with colAlertBackground
                    .cornerRadius(12)
                }
                
                } else {
                    // === NO BUDGET SET MESSAGE ===
                    Text("No budget set")
                        .font(.title)
                        .foregroundColor(.colEmptyStateText)
                        .padding(.top, 100)
                }
                
                // Add bottom padding for safe scrolling
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal)
        }
        .background(Color.colBackground.ignoresSafeArea(.container, edges: .top))
        .onAppear {
            showElements = false
            // Ensure state is properly reset when view appears
            selectedExpenseForDetail = nil
            selectedCategoryForDetail = nil
            
            withAnimation {
                showElements = true
            }
            
            // Set global background color to prevent white flashes during sheet transitions
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.backgroundColor = UIColor(Color.colBackground)
            }
        }
        .onDisappear {
            showElements = false
        }
        .sheet(item: $selectedExpenseForDetail, onDismiss: {
            // Explicitly clear the selected expense to prevent state issues
            selectedExpenseForDetail = nil
        }) { expense in
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                ExpenseDetailView(dataManager: dataManager, expense: expense)
            }
        }
        .fullScreenCover(isPresented: $showingCategoryDetail, onDismiss: {
            // Clear the selected category when dismissed
            selectedCategoryForDetail = nil
        }) {
            CategoryDetailView(dataManager: dataManager, initialCategory: selectedCategoryForDetail, dateRange: nil, historicalBudget: nil)
        }
        .sheet(isPresented: $showingBudgetEdit) {
            BudgetEditView(dataManager: dataManager, isPresented: $showingBudgetEdit)
        }
        .sheet(isPresented: $showingSpendingView) {
            SpendingGraphView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingAllExpenses) {
            AllExpensesView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingSpendingGraph) {
            SpendingGraphView(dataManager: dataManager)
        }
    }
}

// MARK: - All Expenses View
struct AllExpensesView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var selectedCategoryForDetail: CustomCategory? = nil
    @State private var showingCategoryDetail = false
    @AppStorage("selectedTimeFrame") private var selectedTimeFrame: TimeFrame = .currentPeriod
    @State private var selectedCategories: [CustomCategory] = []
    @State private var showingCategoryPicker = false
    @State private var showingAmountFilter = false
    @AppStorage("minAmount") private var minAmount: String = ""
    @AppStorage("maxAmount") private var maxAmount: String = ""
    @State private var showingSortPicker = false
    @AppStorage("selectedSort") private var selectedSort: SortOption = .date
    @AppStorage("selectedCategoryIDs") private var selectedCategoryIDsString: String = ""
    @State private var isEditMode = false
    @State private var selectedExpenseForEdit: Expense? = nil
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case category = "Category"
        case amount = "Amount"
        
        var icon: String {
            switch self {
            case .date: return "calendar"
            case .category: return "tag"
            case .amount: return "dollarsign"
            }
        }
    }
    
    enum TimeFrame: String, CaseIterable {
        case currentPeriod = "This Period"
        case all = "All Time"
        
        var icon: String {
            switch self {
            case .currentPeriod: return "calendar"
            case .all: return "clock.arrow.circlepath"
            }
        }
        
        var displayName: String {
            switch self {
            case .currentPeriod:
                guard let budget = BudgetDataManager().budget else { return "This Period" }
                switch budget.period {
                case .daily: return "Today"
                case .weekly: return "This Week"
                case .monthly: return "This Month"
                case .yearly: return "This Year"
                }
            case .all:
                return "All Time"
            }
        }
    }
    
    private var filteredExpenses: [Expense] {
        let baseExpenses = selectedTimeFrame == .currentPeriod ? dataManager.currentPeriodExpenses : dataManager.expenses
        
        var filtered = baseExpenses
        
        // Filter by categories
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { expense in
                selectedCategories.contains { $0.id == expense.effectiveCategory.id }
            }
        }
        
        // Filter by amount range
        let minAmountValue = Double(minAmount) ?? 0
        let maxAmountValue = Double(maxAmount) ?? Double.greatestFiniteMagnitude
        
        if !minAmount.isEmpty || !maxAmount.isEmpty {
            filtered = filtered.filter { expense in
                expense.amount >= minAmountValue && expense.amount <= maxAmountValue
            }
        }
        
        return filtered
    }
    
    private var sortedExpenses: [Expense] {
        switch selectedSort {
        case .date:
            return filteredExpenses.sorted(by: { $0.date > $1.date })
        case .category:
            return filteredExpenses.sorted(by: { $0.effectiveCategory.name < $1.effectiveCategory.name })
        case .amount:
            return filteredExpenses.sorted(by: { $0.amount > $1.amount })
        }
    }
    
    private var availableCategories: [CustomCategory] {
        let allCategories = categoryManager.allCategories
        // Sort with starred categories first, then alphabetically
        return allCategories.sorted { (cat1, cat2) in
            if cat1.isStarred && !cat2.isStarred {
                return true
            } else if !cat1.isStarred && cat2.isStarred {
                return false
            } else {
                return cat1.name < cat2.name
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with view switcher and filter
                VStack(spacing: 16) {
                    // Main view switcher (not a filter)
                    HStack(spacing: 0) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Button(action: {
                                selectedTimeFrame = timeFrame
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: timeFrame.icon)
                                        .font(.subheadline)
                                    
                                    Text(timeFrame == .currentPeriod ? (dataManager.budget?.period == .daily ? "Today" : dataManager.budget?.period == .weekly ? "This Week" : dataManager.budget?.period == .monthly ? "This Month" : dataManager.budget?.period == .yearly ? "This Year" : "This Period") : timeFrame.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTimeFrame == timeFrame ? .white : .colPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTimeFrame == timeFrame ? Color.colAccent : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.colCardBackground)
                    )
                    
                    // Controls row
                    HStack {
                        // Sort button
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
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Category filter button
                            if !availableCategories.isEmpty {
                                Button(action: {
                                    showingCategoryPicker = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "tag.circle")
                                            .font(.subheadline)
                                            .foregroundColor(.colSecondaryText)
                                        
                                        if !selectedCategories.isEmpty {
                                            if selectedCategories.count == 1 {
                                                Text(selectedCategories.first!.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                            } else {
                                                Text("\(selectedCategories.count) categories")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                            }
                                        } else {
                                            Text("Category")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.colSecondaryText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(!selectedCategories.isEmpty ? Color.colAccent.opacity(0.15) : Color.colCardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(!selectedCategories.isEmpty ? Color.colAccent.opacity(0.3) : Color.colAccent.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Amount filter button
                            Button(action: {
                                showingAmountFilter = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.colSecondaryText)
                                    
                                    if !minAmount.isEmpty || !maxAmount.isEmpty {
                                        let rangeText = {
                                            func simplifyNumber(_ numStr: String) -> String {
                                                guard let num = Double(numStr) else { return numStr }
                                                if num >= 1000000 {
                                                    return String(format: "%.1fM", num / 1000000).replacingOccurrences(of: ".0", with: "")
                                                } else if num >= 1000 {
                                                    return String(format: "%.1fK", num / 1000).replacingOccurrences(of: ".0", with: "")
                                                } else {
                                                    return String(format: "%.0f", num)
                                                }
                                            }
                                            
                                            if !minAmount.isEmpty && !maxAmount.isEmpty {
                                                return "$\(simplifyNumber(minAmount))-$\(simplifyNumber(maxAmount))"
                                            } else if !minAmount.isEmpty {
                                                return ">$\(simplifyNumber(minAmount))"
                                            } else {
                                                return "<$\(simplifyNumber(maxAmount))"
                                            }
                                        }()
                                        Text(rangeText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colPrimaryText)
                                    } else {
                                        Text("Amount")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill((!minAmount.isEmpty || !maxAmount.isEmpty) ? Color.colAccent.opacity(0.15) : Color.colCardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke((!minAmount.isEmpty || !maxAmount.isEmpty) ? Color.colAccent.opacity(0.3) : Color.colAccent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.colBackground)
                
                Rectangle()
                    .fill(Color.colAccent.opacity(0.1))
                    .frame(height: 1)
                
                // Content
                ScrollView {
                    if filteredExpenses.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: !selectedCategories.isEmpty ? "tray" : "receipt")
                                .font(.system(size: 50, weight: .ultraLight))
                                .foregroundColor(.colSecondaryText.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text(!selectedCategories.isEmpty ? "No expenses in selected categories" : "No expenses found")
                                    .font(.headline)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text(!selectedCategories.isEmpty ? "Try selecting different categories" : "Start tracking your spending")
                                    .font(.body)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 0) {
                            if selectedSort == .date {
                                // Group expenses by month when sorting by date
                                let groupedByMonth = Dictionary(grouping: sortedExpenses) { expense in
                                    Calendar.current.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
                                }
                                
                                let sortedMonths = groupedByMonth.keys.sorted(by: >)
                            
                            ForEach(sortedMonths, id: \.self) { monthStart in
                                let monthExpenses = groupedByMonth[monthStart] ?? []
                                
                                VStack(spacing: 0) {
                                    // Month header
                                    HStack {
                                        Text(monthStart, format: .dateTime.month(.wide).year())
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                        
                                        Spacer()
                                        
                                        Text(monthExpenses.reduce(0) { $0 + $1.amount }.formattedCurrency())
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, sortedMonths.first == monthStart ? 8 : 20)
                                    .padding(.bottom, 12)
                                    
                                    // Top border line
                                    Rectangle()
                                        .fill(Color.colAccent.opacity(0.2))
                                        .frame(height: 1)
                                        .padding(.horizontal, 20)
                                    
                                    // Month expenses
                                    ForEach(monthExpenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                                        ExpenseRowView(expense: expense, dataManager: dataManager, selectedExpenseForDetail: $selectedExpenseForDetail, selectedExpenseForEdit: $selectedExpenseForEdit, selectedCategoryForDetail: $selectedCategoryForDetail, showingCategoryDetail: $showingCategoryDetail, isEditMode: isEditMode)
                                    }
                                    
                                    // Bottom border line
                                    Rectangle()
                                        .fill(Color.colAccent.opacity(0.2))
                                        .frame(height: 1)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 8)
                                }
                            }
                            } else {
                                // Simple list when sorting by category or amount
                                ForEach(sortedExpenses, id: \.id) { expense in
                                    ExpenseRowView(expense: expense, dataManager: dataManager, selectedExpenseForDetail: $selectedExpenseForDetail, selectedExpenseForEdit: $selectedExpenseForEdit, selectedCategoryForDetail: $selectedCategoryForDetail, showingCategoryDetail: $showingCategoryDetail, isEditMode: isEditMode)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
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
                
                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.white) 
                // for white navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Expenses")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditMode.toggle()
                        }

                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .shadow(color: .colAccent.opacity(0.3), radius: 4, x: 0, y: 2)

                            Image(systemName: isEditMode ? "checkmark" : "pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isEditMode ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isEditMode)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                categories: availableCategories,
                selectedCategories: $selectedCategories,
                isPresented: $showingCategoryPicker
            )
        }
        .sheet(isPresented: $showingAmountFilter) {
            AmountFilterView(
                minAmount: $minAmount,
                maxAmount: $maxAmount,
                isPresented: $showingAmountFilter
            )
        }
        .sheet(isPresented: $showingSortPicker) {
            SortPickerView(
                selectedSort: $selectedSort,
                isPresented: $showingSortPicker
            )
        }
        .onAppear {
            restoreSelectedCategories()
        }
        .onChange(of: selectedCategories) { _ in
            saveSelectedCategories()
        }
        .sheet(item: $selectedExpenseForEdit) { expense in
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                ExpenseDetailView(dataManager: dataManager, expense: expense)
            }
        }
        .sheet(isPresented: $showingCategoryDetail) {
            CategoryDetailView(
                dataManager: dataManager,
                initialCategory: selectedCategoryForDetail
            )
        }
    }
    
    // MARK: - Helper Methods for Category Persistence
    private func saveSelectedCategories() {
        let categoryIDs = selectedCategories.map { $0.id.uuidString }
        selectedCategoryIDsString = categoryIDs.joined(separator: ",")
    }
    
    private func restoreSelectedCategories() {
        guard !selectedCategoryIDsString.isEmpty else { return }
        let categoryIDStrings = selectedCategoryIDsString.split(separator: ",").map(String.init)
        let categoryIDs = categoryIDStrings.compactMap { UUID(uuidString: $0) }
        selectedCategories = categoryManager.allCategories.filter { category in
            categoryIDs.contains(category.id)
        }
    }
}

// MARK: - Expense Row View
struct ExpenseRowView: View {
    let expense: Expense
    let dataManager: BudgetDataManager
    @Binding var selectedExpenseForDetail: Expense?
    @Binding var selectedExpenseForEdit: Expense?
    @Binding var selectedCategoryForDetail: CustomCategory?
    @Binding var showingCategoryDetail: Bool
    let isEditMode: Bool
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Delete button (only visible in edit mode)
            if isEditMode {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        deleteExpense()
                    }

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 32, height: 32)

                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isEditMode ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isEditMode)
            }

            // Category icon
            ZStack {
                Circle()
                    .fill(expense.effectiveCategory.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: expense.effectiveCategory.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(expense.effectiveCategory.color)
            }

            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                Text({
                    let text = expense.note.isEmpty ? "Untitled" : expense.note
                    return text.count > 25 ? String(text.prefix(25)) + "..." : text
                }())
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.colPrimaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text({
                        let categoryName = expense.effectiveCategory.name
                        if isEditMode && categoryName.count > 12 {
                            return String(categoryName.prefix(9)) + "..."
                        }
                        return categoryName
                    }())
                        .font(.caption)
                        .foregroundColor(expense.effectiveCategory.color)
                        .lineLimit(1)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText.opacity(0.5))

                    Text(expense.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }
            }

            Spacer()

            // Amount
            Text(expense.amount.formattedCurrency())
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.colPrimaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.colBackground)
        .offset(x: shakeOffset)
        .onTapGesture {
            if isEditMode {
                selectedExpenseForEdit = expense
            } else {
                selectedCategoryForDetail = expense.effectiveCategory
                showingCategoryDetail = true
            }
        }
        .onAppear {
            if isEditMode {
                startShakeAnimation()
            }
        }
        .onChange(of: isEditMode) { editMode in
            if editMode {
                startShakeAnimation()
            } else {
                stopShakeAnimation()
            }
        }
    }

    private func startShakeAnimation() {
        withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 1.5
        }
    }

    private func stopShakeAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            shakeOffset = 0
        }
    }

    private func deleteExpense() {
        if let index = dataManager.expenses.firstIndex(where: { $0.id == expense.id }) {
            dataManager.expenses.remove(at: index)
        }
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerView: View {
    let categories: [CustomCategory]
    @Binding var selectedCategories: [CustomCategory]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Clear all filters option
                    Button(action: {
                        selectedCategories = []
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.colSecondaryText.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.colSecondaryText)
                            }
                            
                            Text("Clear All Filters")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.colPrimaryText)
                            
                            Spacer()
                            
                            if selectedCategories.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.colAccent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        VStack(spacing: 0) {
                            Button(action: {
                                if selectedCategories.contains(where: { $0.id == category.id }) {
                                    selectedCategories.removeAll { $0.id == category.id }
                                } else {
                                    selectedCategories.append(category)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: category.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(category.color)
                                    }
                                    
                                    Text(category.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)
                                    
                                    if category.isStarred {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCategories.contains(where: { $0.id == category.id }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.colAccent)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Separator line (except for last item)
                            if index < categories.count - 1 {
                                Rectangle()
                                    .fill(Color.colAccent.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.colBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }
                
                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.white) 
                // for white navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Filter by Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Amount Filter Sheet
struct AmountFilterView: View {
    @Binding var minAmount: String
    @Binding var maxAmount: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Filter by Amount")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                    
                    Text("Set min and max amounts")
                        .font(.body)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Minimum amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Amount")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.colPrimaryText)
                        
                        HStack {
                            Text("$")
                                .font(.title3)
                                .foregroundColor(.colSecondaryText)
                            
                            TextField("0", text: $minAmount)
                                .font(.title3)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Maximum amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Amount")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.colPrimaryText)
                        
                        HStack {
                            Text("$")
                                .font(.title3)
                                .foregroundColor(.colSecondaryText)
                            
                            TextField("1000", text: $maxAmount)
                                .font(.title3)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Clear filter button
                    Button(action: {
                        hideKeyboard()
                        minAmount = ""
                        maxAmount = ""
                    }) {
                        Text("Clear Amount Filter")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.colAccent)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.colAccent.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.colBackground.ignoresSafeArea())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hideKeyboard()
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }
                
                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.white) 
                // for white navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Amount Filter")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Sort Picker Sheet
struct SortPickerView: View {
    @Binding var selectedSort: AllExpensesView.SortOption
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(AllExpensesView.SortOption.allCases, id: \.self) { sortOption in
                        Button(action: {
                            selectedSort = sortOption
                            isPresented = false
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.colAccent.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: sortOption.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.colAccent)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sortOption.rawValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)
                                    
                                    Text({
                                        switch sortOption {
                                        case .date: return "Newest to oldest"
                                        case .category: return "Alphabetical order"
                                        case .amount: return "Highest to lowest"
                                        }
                                    }())
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)
                                }
                                
                                Spacer()
                                
                                if selectedSort == sortOption {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.colAccent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Separator line (except for last item)
                        if sortOption != AllExpensesView.SortOption.allCases.last {
                            Rectangle()
                                .fill(Color.colAccent.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.colBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }
                
                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.white) 
                // for white navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Sort Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Today View Component
struct TodayView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @State private var showingSpendingGraph = false
    @State private var showingTodayExpenses = false
    @State private var currentDate = Date()
    @State private var timer: Timer?
    
    private var todayExpenses: [Expense] {
        let today = Calendar.current.startOfDay(for: currentDate)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return dataManager.expenses.filter { expense in
            expense.date >= today && expense.date < tomorrow
        }
    }
    
    private var todaySpending: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var dailyBudgetTarget: Double? {
        guard let budget = dataManager.budget else { return nil }
        switch budget.period {
        case .daily:
            return budget.amount
        case .weekly:
            return budget.amount / 7
        case .monthly:
            return budget.amount / 30.44
        case .yearly:
            return budget.amount / 365
        }
    }
    
    
    var body: some View {
        VStack(spacing: 18) {
            // Header with better spacing
            HStack {
                HStack(spacing: 8) {
                    Text("Today")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    //Button(action: {
                      //  showingTodayExpenses = true
                    //}) {
                      //  Image(systemName: "chevron.right")
                        //    .font(.caption)
                          //  .foregroundColor(.colAccent)
                    //}
                    Spacer()

                    Button(action: {
                        showingTodayExpenses = true
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.colAccent)
                    }
                }

                Spacer()

               
            }
            
            // Status comparison above spending amount
            if let dailyTarget = dailyBudgetTarget {
                let spendingRatio = todaySpending / dailyTarget
                Text(spendingRatio <= 1.0 ? "On Par" : "Off Par")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(spendingRatio <= 1.0 ? .green : .red)
                    .padding(.bottom, 8)
            }
            
            // Main spending display (larger, centered)
            Text(todaySpending.formattedCurrency())
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.colPrimaryText)
            
            // Lotus health indicator
            if let dailyTarget = dailyBudgetTarget {
                LotusHealthView(spendingRatio: todaySpending / dailyTarget)
                    .padding(.top, 12)
            }
            
            // Today's expenses - more compact
            if !todayExpenses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Today's Expenses")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Spacer()

                        if todayExpenses.count > 3 {
                            Text("+\(todayExpenses.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.colSecondaryText)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(todayExpenses.prefix(3), id: \.id) { expense in
                            VStack(spacing: 6) {
                                Image(systemName: expense.effectiveCategory.icon)
                                    .font(.title3)
                                    .foregroundColor(expense.effectiveCategory.color)
                                    .frame(height: 20)
                                
                                Text(expense.amount.formattedCurrency())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                                
                                Text(expense.note.isEmpty ? expense.effectiveCategory.name : expense.note)
                                    .font(.caption2)
                                    .foregroundColor(.colSecondaryText)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(expense.effectiveCategory.color.opacity(0.1))
                            )
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            showingTodayExpenses = true
        }
        .sheet(isPresented: $showingSpendingGraph) {
            SpendingGraphView(dataManager: dataManager, initialSelectedIndex: 6)
        }
        .sheet(isPresented: $showingTodayExpenses) {
            TodayExpensesView(expenses: todayExpenses, dataManager: dataManager)
        }
        .onAppear {
            startDateUpdateTimer()
        }
        .onDisappear {
            stopDateUpdateTimer()
        }
    }

    private func startDateUpdateTimer() {
        stopDateUpdateTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let newDate = Date()
            let currentDay = Calendar.current.startOfDay(for: currentDate)
            let newDay = Calendar.current.startOfDay(for: newDate)

            if currentDay != newDay {
                currentDate = newDate
            }
        }
    }

    private func stopDateUpdateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Today's Expenses Popup View
struct TodayExpensesView: View {
    let expenses: [Expense]
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var selectedCardID: String? = nil
    @State private var selectedCategoryForDetail: CustomCategory? = nil
    @State private var showingCategoryDetail = false

    // MARK: - Insights Calculations
    private var todaySpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var dailyBudget: Double {
        guard let budget = dataManager.budget else { return 0 }
        switch budget.period {
        case .daily:
            return budget.amount
        case .weekly:
            return budget.amount / 7
        case .monthly:
            return budget.amount / 30
        case .yearly:
            return budget.amount / 365
        }
    }

    private var trendValue: String {
        // Calculate yesterday's spending for comparison
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayExpenses = dataManager.expenses.filter {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        }
        let yesterdaySpent = yesterdayExpenses.reduce(0) { $0 + $1.amount }

        let difference = todaySpent - yesterdaySpent
        let prefix = difference >= 0 ? "+" : "-"
        return "\(prefix)\(abs(difference).formattedCurrency())"
    }

    private var trendSubtitle: String {
        return "Vs yesterday"
    }

    private var topCategoryValue: String {
        guard !expenses.isEmpty else { return "$0" }

        let categoryTotals = Dictionary(grouping: expenses, by: { $0.effectiveCategory.name })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        if let topCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            return topCategory.value.formattedCurrency()
        }
        return "$0"
    }

    private var topCategorySubtitle: String {
        guard !expenses.isEmpty else { return "No expenses" }

        let categoryTotals = Dictionary(grouping: expenses, by: { $0.effectiveCategory.name })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        if let topCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            return topCategory.key
        }
        return "No data"
    }

    private var biggestPurchaseValue: String {
        guard !expenses.isEmpty else { return "$0" }

        if let biggestExpense = expenses.max(by: { $0.amount < $1.amount }) {
            return biggestExpense.amount.formattedCurrency()
        }
        return "$0"
    }

    private var biggestPurchaseSubtitle: String {
        guard !expenses.isEmpty else { return "No purchases" }

        if let biggestExpense = expenses.max(by: { $0.amount < $1.amount }) {
            let note = biggestExpense.note.isEmpty ? "No description" : biggestExpense.note
            return note.count > 20 ? String(note.prefix(20)) + "..." : note
        }
        return "No data"
    }

    private var streakValue: String {
        let isUnderBudget = todaySpent <= dailyBudget
        let streak = isUnderBudget ? calculateUnderBudgetStreak() : calculateOverBudgetStreak()
        return "\(streak) day\(streak == 1 ? "" : "s")"
    }

    private var streakSubtitle: String {
        let isUnderBudget = todaySpent <= dailyBudget
        return isUnderBudget ? "Under budget" : "Over budget"
    }

    private func calculateUnderBudgetStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today

        // Check today first
        let todayExpenses = dataManager.expenses.filter {
            calendar.isDate($0.date, inSameDayAs: currentDate)
        }
        let todayTotal = todayExpenses.reduce(0) { $0 + $1.amount }

        if todayTotal <= dailyBudget {
            streak += 1
        } else {
            return 0
        }

        // Check previous days
        for _ in 1...6 { // Check up to 7 days total
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            let dayExpenses = dataManager.expenses.filter {
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }
            let dayTotal = dayExpenses.reduce(0) { $0 + $1.amount }

            if dayTotal <= dailyBudget {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private func calculateOverBudgetStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today

        // Check today first
        let todayExpenses = dataManager.expenses.filter {
            calendar.isDate($0.date, inSameDayAs: currentDate)
        }
        let todayTotal = todayExpenses.reduce(0) { $0 + $1.amount }

        if todayTotal > dailyBudget {
            streak += 1
        } else {
            return 0
        }

        // Check previous days
        for _ in 1...6 { // Check up to 7 days total
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            let dayExpenses = dataManager.expenses.filter {
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }
            let dayTotal = dayExpenses.reduce(0) { $0 + $1.amount }

            if dayTotal > dailyBudget {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // MARK: - Insights Section
                        VStack(spacing: 20) {
                            // Insights header
                            HStack {
                                Text("Insights")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Spacer()
                            }

                            // Insights grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                UnifiedStatCard(
                                    title: "Trend",
                                    value: trendValue,
                                    subtitle: trendSubtitle,
                                    icon: "chart.line.downtrend.xyaxis",
                                    color: .colAccent,
                                    isSelected: selectedCardID == "trend",
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCardID = selectedCardID == "trend" ? nil : "trend"
                                        }
                                    }
                                )

                                UnifiedStatCard(
                                    title: "Top Category",
                                    value: topCategoryValue,
                                    subtitle: topCategorySubtitle,
                                    icon: "fork.knife",
                                    color: .colAccent,
                                    isSelected: selectedCardID == "top_category",
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCardID = selectedCardID == "top_category" ? nil : "top_category"
                                        }
                                    }
                                )

                                UnifiedStatCard(
                                    title: "Biggest Buy",
                                    value: biggestPurchaseValue,
                                    subtitle: biggestPurchaseSubtitle,
                                    icon: "banknote",
                                    color: .colAccent,
                                    isSelected: selectedCardID == "biggest_purchase",
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCardID = selectedCardID == "biggest_purchase" ? nil : "biggest_purchase"
                                        }
                                    }
                                )

                                UnifiedStatCard(
                                    title: "Streak",
                                    value: streakValue,
                                    subtitle: streakSubtitle,
                                    icon: "bolt.fill",
                                    color: .colAccent,
                                    isSelected: selectedCardID == "streak",
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCardID = selectedCardID == "streak" ? nil : "streak"
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
                        .padding(.horizontal)

                        // MARK: - Expenses List
                        LazyVStack(spacing: 16) {
                            ForEach(expenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                                HStack(spacing: 12) {
                                    Image(systemName: expense.effectiveCategory.icon)
                                        .font(.title2)
                                        .foregroundColor(expense.effectiveCategory.color)
                                        .frame(width: 24, height: 24)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(expense.note.isEmpty ? "No note" : expense.note)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colPrimaryText)
                                            .multilineTextAlignment(.leading)

                                        HStack {
                                            Text(expense.effectiveCategory.name)
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
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                                .onTapGesture {
                                    selectedCategoryForDetail = expense.effectiveCategory
                                    showingCategoryDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Bottom padding for safe scrolling
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
                .background(Color.colBackground)
            }
            .navigationTitle("Today's Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colBackButtonIcon)
                    }
                }
            }
        }
        .sheet(item: $selectedExpenseForDetail) { expense in
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)
                ExpenseDetailView(dataManager: dataManager, expense: expense)
            }
        }
        .sheet(isPresented: $showingCategoryDetail) {
            CategoryDetailView(
                dataManager: dataManager,
                initialCategory: selectedCategoryForDetail
            )
        }
    }
}



// MARK: - Preview
#if DEBUG
struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.budget = Budget(amount: 100.0, period: .monthly, dateCreated: Date())
        dataManager.expenses = [
            Expense(amount: 25.0, note: "Lunch", date: Date(), category: .food),
            Expense(amount: 15.0, note: "Coffee", date: Date(), category: .food),
            Expense(amount: 30.0, note: "Uber", date: Date(), category: .transport),
            Expense(amount: 12.0, note: "Movie ticket", date: Date(), category: .entertainment)
        ]
        return ProgressView(dataManager: dataManager)
            .previewDisplayName("Progress Screen")
    }
}
#endif

// MARK: - Lotus Health View with SF Symbol
struct LotusHealthView: View {
    let spendingRatio: Double

    private var lotusState: LotusState {
        if spendingRatio <= 0.6 {
            return .healthy
        } else if spendingRatio <= 1.0 {
            return .warning
        } else {
            return .overspent
        }
    }

    private enum LotusState {
        case healthy, warning, overspent

        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .overspent: return .red
            }
        }

        var scale: Double {
            switch self {
            case .healthy: return 1.0
            case .warning: return 0.85
            case .overspent: return 0.7
            }
        }

        var opacity: Double {
            switch self {
            case .healthy: return 1.0
            case .warning: return 0.8
            case .overspent: return 0.6
            }
        }
    }

    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 40))
            .foregroundColor(lotusState.color)
            .scaleEffect(lotusState.scale)
            .opacity(lotusState.opacity)
            .animation(.easeInOut(duration: 1.5), value: lotusState.scale)
            .animation(.easeInOut(duration: 1.5), value: lotusState.opacity)
            .animation(.easeInOut(duration: 1.5), value: lotusState.color)
    }
}

