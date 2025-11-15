import SwiftUI

// MARK: - Progress Screen - BUDGET OVERVIEW AND STATISTICS
struct ProgressView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @EnvironmentObject var themeManager: ThemeManager
    let isActiveTab: Bool
    @Binding var selectedTab: Int
    @State private var showElements = false        // Controls entrance animations
    @State private var showingCategoryDetail = false
    @State private var selectedCategoryForDetail: CustomCategory? = nil
    @State private var selectedExpenseForDetail: Expense? = nil
    @State private var selectedCategoryForAnalytics: CustomCategory? = nil
    @State private var showingBudgetEdit = false
    @State private var showingSpendingView = false
    @State private var showingAllExpenses = false
    @State private var showingSpendingGraph = false
    @State private var showingCalendarView = false
    @State private var showingBudgetDetails = false

    // MARK: - Today's Spending Calculations
    private var todaySpent: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var todayExpenses: [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return dataManager.expenses.filter { expense in
            expense.date >= today && expense.date < tomorrow
        }
    }

    private var yesterdaySpent: Double {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayExpenses = dataManager.expenses.filter {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        }
        return yesterdayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var yesterdayDifference: Double {
        return todaySpent - yesterdaySpent
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if let budget = dataManager.budget {
                    // === TOP SPACING ===
                    Color.clear.frame(height: 80) // Space for fixed logo

                // === HEADER SECTION ===
                VStack(spacing: 20) {
                    // Main heading
                    Text("Home")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.colSecondaryText)
                        .textCase(.uppercase)
                        .tracking(1)
                        .opacity(showElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4), value: showElements)
                }

                // === DIVIDER ===
                Rectangle()
                    .fill(Color.colSecondaryText.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: showElements)

                // === TOTAL SPENT CARD AND CALENDAR BUTTON ===
                HStack(alignment: .top, spacing: 8) {
                    // Total Spent Card (2/3 width)
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Spending")
                                .font(.subheadline)
                                .foregroundColor(.colSecondaryText)

                            Text(todaySpent.formattedCurrency())
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.colPrimaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Quick stats row
                        HStack(spacing: 12) {
                            StatPill(
                                icon: yesterdayDifference >= 0 ? "arrow.up" : "arrow.down",
                                value: abs(yesterdayDifference).formattedCurrency(),
                                label: "vs yesterday",
                                color: yesterdayDifference >= 0 ? .red : .green
                            )

                            StatPill(
                                icon: "number",
                                value: "\(todayExpenses.count)",
                                label: "transactions",
                                color: .colAccent
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.colCardBackground)
                            .shadow(color: themeManager.currentTheme == .midnight ? .white.opacity(0.05) : .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.62 + 5)
                    .opacity(showElements ? 1.0 : 0.0)

                    // Right side buttons stack
                    VStack(spacing: 8) {
                        // Calendar Button
                        Button(action: {
                            showingCalendarView = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.colAccent)

                                Text("Calendar")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.colPrimaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: themeManager.currentTheme == .midnight ? .white.opacity(0.05) : .black.opacity(0.06), radius: 12, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Budget Button
                        Button(action: {
                            showingBudgetDetails = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.colAccent)

                                Text("Budget")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.colPrimaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: themeManager.currentTheme == .midnight ? .white.opacity(0.05) : .black.opacity(0.06), radius: 12, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Add New Button
                        Button(action: {
                            selectedTab = 3 // Switch to Log Expense tab
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.colAccent)

                                Text("Add New")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.colPrimaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: themeManager.currentTheme == .midnight ? .white.opacity(0.05) : .black.opacity(0.06), radius: 12, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 8)
                .opacity(showElements ? 1.0 : 0.0)

                // === BUDGET OVERVIEW CARD ===
                BudgetOverviewCard(dataManager: dataManager, showElements: showElements)
                .padding(.horizontal, 8)
               // .padding(.top, )
                .padding(.bottom, 17)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.colCardBackground)
                )
                .opacity(showElements ? 1.0 : 0.0)
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
                    VStack(alignment: .leading, spacing: 12) {
                        // === DIVIDER ===
                        Rectangle()
                            .fill(Color.colSecondaryText.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 24)

                        HStack {
                            Text("Recent Expenses")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            // See All button - compact style
                            Button(action: {
                                showingAllExpenses = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("See All")
                                        .font(.system(size: 13, weight: .medium))

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.colAccent)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                        
                        // Group expenses by category for consistent styling (exclude future expenses)
                        let now = Date()
                        let nonFutureExpenses = dataManager.expenses.filter { $0.date <= now }
                        let recentExpenses = Array(nonFutureExpenses.sorted(by: { $0.date > $1.date }).prefix(3))
                        let groupedExpenses = Dictionary(grouping: recentExpenses) { expense in
                            expense.effectiveCategory
                        }
                        
                        // Sort categories by most recent expense date, then by total amount, then alphabetically by category name
                        let sortedCategories = Array(groupedExpenses.keys).sorted { category1, category2 in
                            let mostRecentDate1 = groupedExpenses[category1]?.max(by: { $0.date < $1.date })?.date ?? Date.distantPast
                            let mostRecentDate2 = groupedExpenses[category2]?.max(by: { $0.date < $1.date })?.date ?? Date.distantPast

                            // First, sort by most recent date
                            if mostRecentDate1 != mostRecentDate2 {
                                return mostRecentDate1 > mostRecentDate2
                            }

                            // If dates are equal, sort by category total spending
                            let total1 = groupedExpenses[category1]?.reduce(0) { $0 + $1.amount } ?? 0
                            let total2 = groupedExpenses[category2]?.reduce(0) { $0 + $1.amount } ?? 0

                            if total1 != total2 {
                                return total1 > total2
                            }

                            // If amounts are equal, sort alphabetically by category name
                            return category1.name < category2.name
                        }
                        
                        ForEach(sortedCategories, id: \.self) { category in
                            let categoryExpenses = groupedExpenses[category] ?? []
                            let categoryTotal = categoryExpenses.reduce(0) { sum, expense in
                                sum + expense.amount
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                // Category header with total
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(category.color)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(category.color.opacity(0.15))
                                        )

                                    Text(category.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.colPrimaryText)

                                    Spacer()

                                    Text(categoryTotal.formattedCurrency())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.colPrimaryText)
                                }

                                // Individual expenses in this category
                                ForEach(categoryExpenses.sorted(by: { $0.date > $1.date }), id: \.id) { expense in
                                    Button(action: {
                                        selectedExpenseForDetail = expense
                                    }) {
                                        RecentExpenseCard(expense: expense, category: category)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: themeManager.currentTheme == .midnight ? .white.opacity(0.03) : .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                }


                } else {
                    // === NO BUDGET SET MESSAGE ===
                    Text("No budget set")
                        .font(.title)
                        .foregroundColor(.colEmptyStateText)
                        .padding(.top, 100)
                }
                
                // Add bottom padding for safe scrolling
                Color.clear.frame(height: UIScreen.main.bounds.height < 700 ? 100 : 80)
            }
            .padding(.horizontal)
        }
        .background(Color.colBackground.ignoresSafeArea(.container, edges: .top))
        .onChange(of: isActiveTab) { isActive in
            if !isActive {
                // Tab switched away - reset after tiny delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showElements = false
                }
            } else {
                // Tab became active - reset then animate in
                showElements = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showElements = true
                    }
                }
            }
        }
        .onAppear {
            if isActiveTab {
                // Reset state immediately without animation
                showElements = false
                selectedExpenseForDetail = nil
                selectedCategoryForDetail = nil

                // Small delay to ensure clean reset, then animate in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        showElements = true
                    }
                }

                // Set global background color to prevent white flashes during sheet transitions
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.backgroundColor = UIColor(Color.colBackground)
                }
            }
        }
        .fullScreenCover(item: $selectedExpenseForDetail, onDismiss: {
            // Explicitly clear the selected expense to prevent state issues
            selectedExpenseForDetail = nil
        }) { expense in
            TransactionDetailView(
                dataManager: dataManager,
                expense: expense,
                allExpenses: dataManager.currentPeriodExpenses.sorted(by: { $0.date > $1.date }),
                isPresented: Binding(
                    get: { selectedExpenseForDetail != nil },
                    set: { if !$0 { selectedExpenseForDetail = nil } }
                ),
                parentCategory: nil
            )
        }
        .fullScreenCover(isPresented: $showingCategoryDetail, onDismiss: {
            // Clear the selected category when dismissed
            selectedCategoryForDetail = nil
        }) {
            CircleExpansionView(dataManager: dataManager, initialCategory: selectedCategoryForDetail, dateRange: nil, historicalBudget: nil)
        }
        .sheet(isPresented: $showingBudgetEdit) {
            BudgetEditView(dataManager: dataManager, isPresented: $showingBudgetEdit)
        }
        .sheet(isPresented: $showingSpendingView) {
            SpendingGraphView(dataManager: dataManager)
        }
        .fullScreenCover(isPresented: $showingAllExpenses) {
            AllExpensesView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingSpendingGraph) {
            SpendingGraphView(dataManager: dataManager)
        }
        .fullScreenCover(item: $selectedCategoryForAnalytics) { category in
            CategoryDetailView(dataManager: dataManager, category: category)
        }
        .fullScreenCover(isPresented: $showingCalendarView) {
            CalendarView(dataManager: dataManager, selectedMonth: nil)
        }
        .fullScreenCover(isPresented: $showingBudgetDetails) {
            ProgressViewBudget(dataManager: dataManager)
        }
    }

    // Helper function to abbreviate large amounts
    private func abbreviateAmount(_ amount: Double) -> String {
        let symbol = String.currencySymbol()
        if amount >= 1_000_000_000 {
            return String(format: "%@%.1fB", symbol, amount / 1_000_000_000).replacingOccurrences(of: ".0B", with: "B")
        } else if amount >= 1_000_000 {
            return String(format: "%@%.1fM", symbol, amount / 1_000_000).replacingOccurrences(of: ".0M", with: "M")
        } else if amount >= 1_000 {
            return String(format: "%@%.1fK", symbol, amount / 1_000).replacingOccurrences(of: ".0K", with: "K")
        } else {
            return String(format: "%@%.2f", symbol, amount)
        }
    }
}
