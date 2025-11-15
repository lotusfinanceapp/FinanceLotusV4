import SwiftUI

// MARK: - Analytics Screen - Category Breakdown & Insights
struct AnalyticsView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @State private var showingSpendingGraph = false
    @State private var showingCompareView = false
    @State private var showingRecurringExpenses = false
    @State private var selectedCategory: CustomCategory?
    @State private var showElements = false
    @State private var selectedTransaction: Expense?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // === TOP SPACING ===
                Color.clear.frame(height: 70)

                // === STATS OVERVIEW ===
                if let totalSpent = totalSpentForTimeFrame() {
                    VStack(spacing: 24) {
                        // Total Spent - Large Display
                        VStack(spacing: 8) {
                            Text("Total Spent")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.colSecondaryText)
                                .textCase(.uppercase)
                                .tracking(1)

                            Text(totalSpent.formattedCurrency())
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.colPrimaryText)
                        }

                        // Secondary Stats Row
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("\(transactionCountForTimeFrame())")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.colPrimaryText)

                                Text("Transactions")
                                    .font(.caption)
                                    .foregroundColor(.colSecondaryText)
                            }

                            if let changeInfo = monthOverMonthChange() {
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: changeInfo.isIncrease ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(changeInfo.isIncrease ? .red : .green)

                                        Text(changeInfo.percentageText)
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(changeInfo.isIncrease ? .red : .green)
                                    }

                                    Text("vs Last Month")
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // === DIVIDER ===
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                // === QUICK INSIGHTS ===
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                        .padding(.horizontal, 24)

                    HStack(spacing: 10) {
                        CompactInsightButton(
                            icon: "chart.xyaxis.line",
                            title: "Trends",
                            action: { showingSpendingGraph = true }
                        )

                        CompactInsightButton(
                            icon: "chart.bar.fill",
                            title: "Compare",
                            action: { showingCompareView = true }
                        )

                        CompactInsightButton(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Recurring",
                            action: { showingRecurringExpenses = true }
                        )
                    }
                    .padding(.horizontal, 24)
                }

                // === CATEGORY BREAKDOWN ===
                VStack(alignment: .leading, spacing: 16) {
                    Text("Categories")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                        .padding(.horizontal, 24)

                    VStack(spacing: 10) {
                        // All categories: favorited first, then others
                        ForEach(allCategoriesWithSpending(), id: \.category.id) { item in
                            CategorySpendingCard(
                                category: item.category,
                                amount: item.amount,
                                transactionCount: item.transactionCount,
                                action: {
                                    selectedCategory = item.category
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Bottom spacing
                Color.clear.frame(height: 80)
            }
        }
        .background(Color.colBackground.ignoresSafeArea())
        .onAppear {
            showElements = false
            withAnimation(.easeOut(duration: 0.3)) {
                showElements = true
            }
        }
        .fullScreenCover(isPresented: $showingSpendingGraph) {
            SpendingGraphView(dataManager: dataManager)
        }
        .fullScreenCover(isPresented: $showingCompareView) {
            CompareView(dataManager: dataManager)
        }
        .fullScreenCover(isPresented: $showingRecurringExpenses) {
            RecurringExpensesManagementView(dataManager: dataManager)
        }
        .fullScreenCover(item: $selectedCategory) { category in
            CategoryDetailView(
                dataManager: dataManager,
                category: category
            )
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(
                dataManager: dataManager,
                expense: transaction,
                allExpenses: nil,
                isPresented: Binding(
                    get: { selectedTransaction != nil },
                    set: { if !$0 { selectedTransaction = nil } }
                ),
                parentCategory: nil
            )
        }
    }

    // MARK: - Helper Functions

    private func totalSpentForTimeFrame() -> Double? {
        let expenses = expensesForTimeFrame()
        guard !expenses.isEmpty else { return nil }
        return expenses.reduce(0) { $0 + $1.amount }
    }

    private func transactionCountForTimeFrame() -> Int {
        return expensesForTimeFrame().count
    }

    private func expensesForTimeFrame() -> [Expense] {
        return dataManager.expenses
    }

    private func categoryBreakdown() -> [(category: CustomCategory, amount: Double, percentage: Double, transactionCount: Int)] {
        let expenses = expensesForTimeFrame()
        guard !expenses.isEmpty else { return [] }

        let totalSpent = expenses.reduce(0) { $0 + $1.amount }

        // Group by category
        var categoryTotals: [UUID: (category: CustomCategory, amount: Double, count: Int)] = [:]

        for expense in expenses {
            if let categoryId = expense.categoryId,
               let category = categoryManager.allCategories.first(where: { $0.id == categoryId }) {
                if var existing = categoryTotals[categoryId] {
                    existing.amount += expense.amount
                    existing.count += 1
                    categoryTotals[categoryId] = existing
                } else {
                    categoryTotals[categoryId] = (category: category, amount: expense.amount, count: 1)
                }
            }
        }

        // Convert to array and calculate percentages
        return categoryTotals.values.map { item in
            (
                category: item.category,
                amount: item.amount,
                percentage: (item.amount / totalSpent) * 100,
                transactionCount: item.count
            )
        }.sorted { $0.amount > $1.amount } // Sort by highest spending
    }

    private func allCategoriesWithSpending() -> [(category: CustomCategory, amount: Double, transactionCount: Int)] {
        let expenses = expensesForTimeFrame()

        // Build a dictionary of spending per category
        var categorySpending: [UUID: (amount: Double, count: Int)] = [:]

        for expense in expenses {
            if let categoryId = expense.categoryId {
                if var existing = categorySpending[categoryId] {
                    existing.amount += expense.amount
                    existing.count += 1
                    categorySpending[categoryId] = existing
                } else {
                    categorySpending[categoryId] = (amount: expense.amount, count: 1)
                }
            }
        }

        // Get all categories from CategoryManager
        let allCategories = categoryManager.allCategories

        // Build result array with all categories
        var result: [(category: CustomCategory, amount: Double, transactionCount: Int)] = []

        for category in allCategories {
            let spending = categorySpending[category.id] ?? (amount: 0.0, count: 0)
            result.append((
                category: category,
                amount: spending.amount,
                transactionCount: spending.count
            ))
        }

        // Sort: favorited first (by star order), then others (by spending amount)
        return result.sorted { item1, item2 in
            // Both starred: sort by star order (most recent first)
            if item1.category.isStarred && item2.category.isStarred {
                return (item1.category.starOrder ?? 0) > (item2.category.starOrder ?? 0)
            }
            // Only first is starred: it comes first
            if item1.category.isStarred {
                return true
            }
            // Only second is starred: it comes first
            if item2.category.isStarred {
                return false
            }
            // Neither starred: sort by spending amount (highest first)
            return item1.amount > item2.amount
        }
    }

    private func monthOverMonthChange() -> (percentageText: String, isIncrease: Bool)? {
        let calendar = Calendar.current
        let now = Date()

        // Get current month expenses
        let currentMonthExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
        }
        let currentMonthTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }

        // Get last month expenses
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            return nil
        }
        let lastMonthExpenses = dataManager.expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: lastMonth, toGranularity: .month)
        }
        let lastMonthTotal = lastMonthExpenses.reduce(0) { $0 + $1.amount }

        // If no spending last month, can't calculate percentage
        guard lastMonthTotal > 0 else {
            // If current month has spending but last month didn't
            if currentMonthTotal > 0 {
                return ("100%", true)
            }
            return nil
        }

        // Calculate percentage change
        let change = ((currentMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
        let isIncrease = change > 0

        // Format percentage
        let percentageText = String(format: "%.0f%%", abs(change))

        return (percentageText, isIncrease)
    }
}

// MARK: - Compact Insight Button
struct CompactInsightButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.colAccent)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.colPrimaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Spending Card
struct CategorySpendingCard: View {
    let category: CustomCategory
    let amount: Double
    let transactionCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Category icon
                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .foregroundColor(category.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(category.color.opacity(0.15))
                    )

                // Category name
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                        .lineLimit(1)

                    Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }

                Spacer()

                // Amount and chevron
                HStack(spacing: 10) {
                    Text(amount.formattedCurrency())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.colPrimaryText)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.colSecondaryText.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Minimal Analytics Card
struct MinimalAnalyticsCard: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.colAccent.opacity(0.7))
                }
                .padding(.top, 16)
                .padding(.trailing, 16)

                Spacer()

                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.colPrimaryText)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Old Category Breakdown Row (kept for compatibility)
struct CategoryBreakdownRow: View {
    let category: CustomCategory
    let amount: Double
    let percentage: Double
    let transactionCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(category.color.opacity(0.15))
                        )

                    // Category info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)

                        Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.colSecondaryText)
                    }

                    Spacer()

                    // Amount and percentage
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(amount.formattedCurrency())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)

                        Text(String(format: "%.1f%%", percentage))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(category.color)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText.opacity(0.5))
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.colSecondaryText.opacity(0.1))
                            .frame(height: 6)

                        // Filled portion
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [category.color, category.color.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.colInputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(category.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.colAccent)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.colAccent.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.colSecondaryText.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.colInputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview
#if DEBUG
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        return AnalyticsView(dataManager: dataManager)
            .previewDisplayName("Analytics Screen")
    }
}
#endif
