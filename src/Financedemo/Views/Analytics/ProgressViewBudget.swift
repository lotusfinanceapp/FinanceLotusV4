import SwiftUI

// MARK: - Progress View Budget - DETAILED BUDGET BREAKDOWN
struct ProgressViewBudget: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showElements = false
    @State private var selectedCategory: CustomCategory?
    @State private var categoryToDetail: CustomCategory?
    @State private var selectedMonth = Date()
    @State private var showingMonthPicker = false
    @State private var showingEditBudget = false
    @State private var editBudgetAmount = ""

    // MARK: - Computed Properties
    private var currentBudget: Double {
        dataManager.getBudget(for: selectedMonth)?.amount ?? 0
    }

    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) ?? selectedMonth
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? selectedMonth

        return dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date < startOfNextMonth
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

    private var totalSpentThisMonth: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var spentPercentage: Double {
        guard currentBudget > 0 else { return 0 }
        return min(totalSpentThisMonth / currentBudget, 1.0)
    }

    private var categorySpending: [(category: CustomCategory, amount: Double, percentage: Double)] {
        // Group expenses by category
        let grouped = Dictionary(grouping: currentMonthExpenses) { $0.effectiveCategory }

        // Calculate totals and percentages
        var results: [(category: CustomCategory, amount: Double, percentage: Double)] = []

        for (category, expenses) in grouped {
            let amount = expenses.reduce(0) { $0 + $1.amount }
            // When overspending: calculate percentage based on total spending
            // When under budget: calculate percentage based on budget
            let percentage: Double
            if totalSpentThisMonth > currentBudget {
                // Overspending: show % of total spending
                percentage = totalSpentThisMonth > 0 ? amount / totalSpentThisMonth : 0
            } else {
                // Under budget: show % of budget
                percentage = currentBudget > 0 ? amount / currentBudget : 0
            }
            results.append((category: category, amount: amount, percentage: percentage))
        }

        // Sort by spending amount (highest first)
        return results.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // === TOP SPACING ===
                        Color.clear.frame(height: 20)

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
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // === BUDGET OVERVIEW CARD ===
                        VStack(alignment: .leading, spacing: 20) {
                            // Budget and spent info
                            VStack(alignment: .center, spacing: 0) {
                                HStack(spacing: 30) {
                                    HStack(spacing: 8) {
                                        VStack(alignment: .center, spacing: 4) {
                                            Text("Budget")
                                                .font(.subheadline)
                                                .foregroundColor(.colSecondaryText)
                                            Text(currentBudget.formattedCurrency())
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.colPrimaryText)
                                        }

                                        Button(action: {
                                            editBudgetAmount = String(format: "%.2f", currentBudget)
                                            showingEditBudget = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.colAccent)
                                        }
                                    }

                                    VStack(alignment: .center, spacing: 4) {
                                        Text("Spent")
                                            .font(.subheadline)
                                            .foregroundColor(.colSecondaryText)
                                        Text(totalSpentThisMonth.formattedCurrency())
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.colPrimaryText)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 12)

                                // Divider
                                Rectangle()
                                    .fill(Color.colSecondaryText.opacity(0.1))
                                    .frame(height: 1)
                                    .padding(.bottom, 12)

                                // Remaining amount or Overspent
                                if totalSpentThisMonth > currentBudget {
                                    // Overspending state
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Strikethrough "Remaining"
                                        HStack {
                                            Text("Remaining")
                                                .font(.subheadline)
                                                .foregroundColor(.colSecondaryText)
                                                .strikethrough()

                                            Spacer()

                                            Text("$0.00")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.colSecondaryText)
                                                .strikethrough()
                                        }

                                        // Overspent amount
                                        HStack {
                                            Text("Overspent")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.red)

                                            Spacer()

                                            Text((totalSpentThisMonth - currentBudget).formattedCurrency())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.red)
                                        }
                                    }
                                } else {
                                    // Normal remaining state
                                    HStack {
                                        Text("Remaining")
                                            .font(.subheadline)
                                            .foregroundColor(.colSecondaryText)

                                        Spacer()

                                        Text((currentBudget - totalSpentThisMonth).formattedCurrency())
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            // === VISUAL BUDGET BAR ===
                            VStack(alignment: .leading, spacing: 12) {
                                // Bar with category breakdown
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.colSecondaryText.opacity(0.2), lineWidth: 2)
                                    .background(
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                HStack(spacing: 0) {
                                                    // Reorder: selected category appears first (in front)
                                                    let reorderedSpending = categorySpending.sorted { a, b in
                                                        if a.category.id == selectedCategory?.id { return true }
                                                        if b.category.id == selectedCategory?.id { return false }
                                                        return a.amount > b.amount
                                                    }

                                                    ForEach(reorderedSpending, id: \.category.id) { item in
                                                        let isSelected = selectedCategory?.id == item.category.id
                                                        // Cap percentage at 100% (1.0)
                                                        let cappedPercentage = min(item.percentage, 1.0)

                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(item.category.color)
                                                            .frame(
                                                                width: geometry.size.width * cappedPercentage + (isSelected ? 3 : 0),
                                                                height: 40 + (isSelected ? 2 : 0)
                                                            )
                                                            .animation(.easeInOut(duration: 0.2), value: selectedCategory?.id)
                                                            .onTapGesture {
                                                                selectedCategory = isSelected ? nil : item.category
                                                            }
                                                            .zIndex(isSelected ? 10 : 0)
                                                    }

                                                    Spacer()
                                                }
                                                .cornerRadius(12)
                                            }
                                        }
                                    )
                                    .frame(height: 40)

                                // Percentage text
                                Text("\(Int(spentPercentage * 100))% spent")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.colSecondaryText)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCategory != nil {
                                selectedCategory = nil
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 20)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)

                        // === CATEGORY BREAKDOWN SECTION ===
                        if !categorySpending.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Spending by Category")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.colPrimaryText)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    // Reorder: selected category at the top
                                    let reorderedCategories = categorySpending.sorted { a, b in
                                        if a.category.id == selectedCategory?.id { return true }
                                        if b.category.id == selectedCategory?.id { return false }
                                        return a.amount > b.amount
                                    }

                                    ForEach(reorderedCategories, id: \.category.id) { item in
                                        let isSelected = selectedCategory?.id == item.category.id

                                        HStack(spacing: 12) {
                                            // Category color indicator
                                            Circle()
                                                .fill(item.category.color)
                                                .frame(width: 12, height: 12)

                                            // Category name
                                            Text(item.category.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.colPrimaryText)

                                            Spacer()

                                            // Amount and percentage
                                            HStack(spacing: 8) {
                                                Text(item.amount.formattedCurrency())
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.colPrimaryText)

                                                Text("(\(Int(item.percentage * 100))%)")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.colSecondaryText)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(item.category.color.opacity(isSelected ? 0.2 : 0.1))
                                        )
                                        .opacity(isSelected ? 0.7 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedCategory?.id)
                                        .onTapGesture {
                                            if isSelected {
                                                // Second tap: open category detail view
                                                categoryToDetail = item.category
                                            } else {
                                                // First tap: select category
                                                selectedCategory = item.category
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 20)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.colSecondaryText.opacity(0.5))

                                Text("No Expenses Yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.colPrimaryText)

                                Text("Start logging expenses to see your budget breakdown")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                        }

                        // === BOTTOM SPACING ===
                        Color.clear.frame(height: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.colBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colBackButtonIcon)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Budget Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
            .fullScreenCover(item: $categoryToDetail) { category in
                CategoryDetailView(dataManager: dataManager, category: category, initialMonth: selectedMonth)
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
            .fullScreenCover(isPresented: $showingEditBudget) {
                EditMonthBudgetView(
                    dataManager: dataManager,
                    selectedMonth: selectedMonth,
                    isPresented: $showingEditBudget
                )
            }
            .onAppear {
                showElements = false

                // Configure navigation bar appearance to remove divider
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color.colBackground)
                appearance.shadowColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        showElements = true
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ProgressViewBudget_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        dataManager.setBudget(1000, period: .monthly)

        // Add sample expenses
        let food = dataManager.categoryManager.allCategories.first { $0.name == "Food" } ?? CustomCategory(name: "Food", icon: "fork.knife", colorHex: "#22C55E")
        let transport = dataManager.categoryManager.allCategories.first { $0.name == "Transport" } ?? CustomCategory(name: "Transport", icon: "car.fill", colorHex: "#3B82F6")
        let entertainment = dataManager.categoryManager.allCategories.first { $0.name == "Entertainment" } ?? CustomCategory(name: "Entertainment", icon: "film", colorHex: "#A855F7")

        dataManager.addExpense(250, note: "Groceries", customCategory: food, date: Date())
        dataManager.addExpense(150, note: "Gas", customCategory: transport, date: Date())
        dataManager.addExpense(100, note: "Movies", customCategory: entertainment, date: Date())

        return ProgressViewBudget(dataManager: dataManager)
            .previewDisplayName("Budget Breakdown")
    }
}
#endif
