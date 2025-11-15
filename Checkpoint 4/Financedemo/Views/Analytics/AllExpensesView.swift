import SwiftUI

// MARK: - All Expenses View
struct AllExpensesView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @StateObject private var categoryManager = CategoryManager()
    @Environment(\.dismiss) private var dismiss
    @State private var expenseDetailPresentation: ExpenseDetailPresentation? = nil
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

                                            let symbol = String.currencySymbol()
                                            if !minAmount.isEmpty && !maxAmount.isEmpty {
                                                return "\(symbol)\(simplifyNumber(minAmount))-\(symbol)\(simplifyNumber(maxAmount))"
                                            } else if !minAmount.isEmpty {
                                                return ">\(symbol)\(simplifyNumber(minAmount))"
                                            } else {
                                                return "<\(symbol)\(simplifyNumber(maxAmount))"
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
                                        ExpenseRowView(expense: expense, dataManager: dataManager, expenseDetailPresentation: $expenseDetailPresentation, selectedCategoryForDetail: $selectedCategoryForDetail, showingCategoryDetail: $showingCategoryDetail, isEditMode: isEditMode)
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
                                    ExpenseRowView(expense: expense, dataManager: dataManager, expenseDetailPresentation: $expenseDetailPresentation, selectedCategoryForDetail: $selectedCategoryForDetail, showingCategoryDetail: $showingCategoryDetail, isEditMode: isEditMode)
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

                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.colPrimaryText)
                // for navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Expenses")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
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
                        Image(systemName: isEditMode ? "checkmark.circle.fill" : "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
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
        .sheet(isPresented: $showingCategoryDetail) {
            CircleExpansionView(
                dataManager: dataManager,
                initialCategory: selectedCategoryForDetail
            )
        }
        .fullScreenCover(item: $expenseDetailPresentation) { presentation in
            let _ = print("DEBUG: fullScreenCover triggered - startInEditMode: \(presentation.startInEditMode)")
            TransactionDetailView(
                dataManager: dataManager,
                expense: presentation.expense,
                allExpenses: sortedExpenses,
                isPresented: Binding(
                    get: { expenseDetailPresentation != nil },
                    set: { if !$0 {
                        print("DEBUG: Dismissing")
                        expenseDetailPresentation = nil
                    } }
                ),
                parentCategory: nil,
                startInEditMode: presentation.startInEditMode
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
