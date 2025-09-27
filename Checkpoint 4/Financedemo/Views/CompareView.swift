import SwiftUI

// MARK: - Compare View - MONTH-TO-MONTH COMPARISON
struct CompareView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonths: [Date] = []
    @State private var showingMonthPicker = false
    @State private var selectedCategories: Set<String> = []
    @State private var showingCategoryFilter = false

    // Get available months from expenses
    private var availableMonths: [Date] {
        let months = Set(dataManager.expenses.map { expense in
            Calendar.current.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        })
        return months.sorted(by: >)
    }

    // Get expenses for each selected month
    private func getExpensesForMonth(_ month: Date) -> [Expense] {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = Calendar.current.dateInterval(of: .month, for: month)?.end ?? month
        return dataManager.expenses.filter { expense in
            expense.date >= startOfMonth && expense.date < endOfMonth
        }
    }

    private var monthlyTotals: [Double] {
        selectedMonths.map { month in
            getExpensesForMonth(month).reduce(0) { $0 + $1.amount }
        }
    }

    private var monthlyCategories: [[String: Double]] {
        var result: [[String: Double]] = []
        for month in selectedMonths {
            let expenses = getExpensesForMonth(month)
            let grouped = Dictionary(grouping: expenses, by: { $0.effectiveCategory.name })
            let mapped = grouped.mapValues { expenseList in
                expenseList.reduce(0) { total, expense in
                    total + expense.amount
                }
            }
            result.append(mapped)
        }
        return result
    }

    private var allCategoryObjects: [CustomCategory] {
        let availableCategories = dataManager.expenses.map { $0.effectiveCategory }

        // Deduplicate by category name to avoid duplicate bars
        var uniqueCategoriesDict: [String: CustomCategory] = [:]
        for category in availableCategories {
            uniqueCategoriesDict[category.name] = category
        }
        let uniqueCategories = Array(uniqueCategoriesDict.values)

        if selectedCategories.isEmpty {
            return uniqueCategories.sorted { $0.name < $1.name }
        } else {
            return uniqueCategories.filter { selectedCategories.contains($0.name) }.sorted { $0.name < $1.name }
        }
    }

    private var allCategories: Set<String> {
        if selectedCategories.isEmpty {
            return Set(dataManager.expenses.map { $0.effectiveCategory.name })
        } else {
            return selectedCategories
        }
    }

    private var maxAmount: Double {
        var allAmounts: [Double] = []

        // Add individual category amounts
        for categoryDict in monthlyCategories {
            allAmounts.append(contentsOf: categoryDict.values)
        }

        // Add monthly totals (sum of all categories per month)
        for categoryDict in monthlyCategories {
            let monthTotal = categoryDict.values.reduce(0, +)
            allAmounts.append(monthTotal)
        }

        return allAmounts.max() ?? 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // === TOP SPACING ===
                Color.clear.frame(height: 80)

                // === HEADER SECTION ===
                VStack(spacing: 15) {
                    // Chart icon
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.colChartIcon)

                    // Main heading
                    Text("Compare Spending")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                }

                // === HEADER - MONTH SELECTOR AND FILTERS ===
                VStack(spacing: 16) {
                    // Month selector (main filter)
                    Button(action: {
                        showingMonthPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.colAccent)

                            Text(monthsDisplayText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.colAccent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.colCardBackground)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Filter row
                    HStack {
                        Spacer()

                        // Category filter button
                        Button(action: {
                            showingCategoryFilter = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)

                                if !selectedCategories.isEmpty {
                                    if selectedCategories.count == 1 {
                                        Text(selectedCategories.first!)
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
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.colBackground)

                Rectangle()
                    .fill(Color.colAccent.opacity(0.1))
                    .frame(height: 1)

                // === MAIN CONTENT ===
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // === MONTHLY TOTALS SUMMARY ===
                        if !selectedMonths.isEmpty {
                            VStack(spacing: 16) {
                                Text("Monthly Totals")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(selectedMonths.count, 2)), spacing: 12) {
                                    ForEach(Array(selectedMonths.enumerated()), id: \.offset) { index, month in
                                        VStack(spacing: 8) {
                                            Text(month, format: .dateTime.month(.abbreviated).year())
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.colSecondaryText)

                                            Text(monthlyTotals.indices.contains(index) ? monthlyTotals[index].formattedCurrency() : "$0")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.colPrimaryText)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(monthCardColor(for: index))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.colAccent.opacity(monthCardOpacity(for: index)), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // === MAIN CHART - BAR COMPARISON ===
                        if !allCategoryObjects.isEmpty {
                            VStack(spacing: 20) {
                                // Chart Header
                                VStack(spacing: 12) {
                                    Text("Category Comparison")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.colPrimaryText)

                                    // Legend
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedMonths.enumerated()), id: \.offset) { index, month in
                                            HStack(spacing: 4) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(getColorForMonth(index: index))
                                                    .frame(width: 13, height: 13)
                                                Text(month.formatted(.dateTime.month(.abbreviated)))
                                                    .font(.caption2)
                                                    .foregroundColor(.colSecondaryText)
                                            }
                                        }
                                    }
                                }

                                // Multi-Month Chart
                                if selectedMonths.count >= 1 {
                                    MultiMonthBarChart(
                                        categories: allCategoryObjects,
                                        selectedMonths: selectedMonths,
                                        monthlyData: monthlyCategories,
                                        maxAmount: maxAmount
                                    )
                                } else {
                                    VStack(spacing: 20) {
                                        Image(systemName: "chart.bar")
                                            .font(.system(size: 48))
                                            .foregroundColor(.colAccent.opacity(0.6))

                                        Text("Select a month to view spending")
                                            .font(.title3)
                                            .foregroundColor(.colSecondaryText)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.colCardBackground.opacity(0.3))
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
                            .padding(.horizontal, 20)
                        }

                        // Bottom padding for safe scrolling
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color.colBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthSelectionView(selectedMonths: $selectedMonths)
        }
        .sheet(isPresented: $showingCategoryFilter) {
            CategoryFilterView(
                allCategories: Array(Set(dataManager.expenses.map { $0.effectiveCategory.name })),
                selectedCategories: $selectedCategories
            )
        }
        .onAppear {
            setDefaultMonths()
        }
    }

    // Helper functions
    private var monthsDisplayText: String {
        if selectedMonths.isEmpty {
            return "Select months to compare"
        } else if selectedMonths.count == 1 {
            return selectedMonths[0].formatted(.dateTime.month(.wide).year())
        } else if selectedMonths.count == 2 {
            let monthNames = selectedMonths.map { $0.formatted(.dateTime.month(.abbreviated)) }
            return monthNames.joined(separator: " vs ")
        } else {
            return "\(selectedMonths.count) months"
        }
    }

    private var categoryFilterText: String {
        if selectedCategories.isEmpty {
            return "All Categories"
        } else if selectedCategories.count == 1 {
            return selectedCategories.first ?? "Filter Categories"
        } else {
            return "Filter Categories"
        }
    }

    private func monthCardColor(for index: Int) -> Color {
        let opacities: [Double] = [0.8, 1.0, 0.6, 0.4]
        let opacity = opacities.indices.contains(index) ? opacities[index] : 0.3
        return Color.colCardBackground.opacity(opacity)
    }

    private func monthCardOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.4, 0.6, 0.3, 0.2]
        return opacities.indices.contains(index) ? opacities[index] : 0.2
    }

    private func getColorForMonth(index: Int) -> Color {
        let colors: [Color] = [
            Color.blue,
            Color.green,
            Color.orange,
            Color.purple,
            Color.red,
            Color.cyan
        ]
        return colors.indices.contains(index) ? colors[index] : Color.gray
    }

    private func setDefaultMonths() {
        if availableMonths.count >= 2 {
            selectedMonths = Array(availableMonths.prefix(2))
        } else if availableMonths.count == 1 {
            selectedMonths = [availableMonths[0]]
        }
    }
}

// MARK: - Multi-Month Bar Chart Component
struct MultiMonthBarChart: View {
    let categories: [CustomCategory]
    let selectedMonths: [Date]
    let monthlyData: [[String: Double]]
    let maxAmount: Double

    private let chartHeight: CGFloat = 200
    private let yAxisSteps = 5

    // Calculate safe max amount to prevent division by zero
    private var safeMaxAmount: Double {
        max(maxAmount, 1.0)
    }

    // Generate Y-axis values from bottom to top
    private var yAxisValues: [Double] {
        guard safeMaxAmount > 0 else { return [0] }
        return (0...yAxisSteps).map { step in
            Double(step) * safeMaxAmount / Double(yAxisSteps)
        }.reversed()
    }

    var body: some View {
        // Guard against empty data
        guard !categories.isEmpty && !selectedMonths.isEmpty && !monthlyData.isEmpty else {
            return AnyView(
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32))
                        .foregroundColor(.colAccent.opacity(0.6))
                    Text("No data to display")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                }
                .frame(height: chartHeight)
                .frame(maxWidth: .infinity)
            )
        }

        return AnyView(
            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis with placeholder for category labels
                VStack(spacing: 8) {
                    // Y-axis values
                    VStack(spacing: 0) {
                        ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, value in
                            Spacer()
                            Text(value.formattedCurrency())
                                .font(.caption2)
                                .foregroundColor(.colSecondaryText)
                                .frame(height: 20)
                            if index < yAxisValues.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 60, height: chartHeight)

                    // Placeholder space to match category label height
                    Color.clear
                        .frame(width: 20, height: 10) // Approximate height for 2-line category labels
                }

                // Chart with synchronized scrolling
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        // Gridlines background - using same VStack structure as Y-axis
                        VStack(spacing: 0) {
                            ForEach(Array(yAxisValues.enumerated()), id: \.offset) { index, _ in
                                HStack {
                                    Rectangle()
                                        .fill(Color.colSecondaryText.opacity(0.2))
                                        .frame(height: 0.5)
                                    Spacer()
                                }
                                .frame(height: 20) // Same height as Y-axis labels
                                if index < yAxisValues.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: chartHeight)

                        // Chart content
                        HStack(spacing: 0) {
                            // Total spending comparison (leftmost)
                            let totalCategoryWidth = getCategoryWidth(for: "Total")

                            VStack(spacing: 8) {
                                // Total bars container
                                HStack(alignment: .bottom, spacing: 4) {
                                    ForEach(Array(selectedMonths.enumerated()), id: \.offset) { monthIndex, month in
                                        let monthTotal = monthlyData.indices.contains(monthIndex) ?
                                            monthlyData[monthIndex].values.reduce(0, +) : 0
                                        let normalizedHeight = safeMaxAmount > 0 ? monthTotal / safeMaxAmount : 0
                                        // Calculate bar height using precise percentage approach
                                        let percentage = safeMaxAmount > 0 ? monthTotal / safeMaxAmount : 0
                                        let maxBarHeight = chartHeight - 20 // Max height aligns with top gridline
                                        let adjustedBarHeight = max(CGFloat(percentage) * maxBarHeight, 2.0)

                                        Rectangle()
                                            .fill(getColorForMonth(index: monthIndex))
                                            .frame(width: getBarWidth(), height: adjustedBarHeight)
                                            .cornerRadius(2)
                                    }
                                }
                                .frame(height: chartHeight, alignment: .bottom)

                                // Total label
                                Text("Total")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                            }
                            .frame(width: totalCategoryWidth)

                            // Add spacing after total
                            Spacer()
                                .frame(width: getSpacingAfterCategory("Total"))

                            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                                let categoryWidth = getCategoryWidth(for: category.name)

                                VStack(spacing: 8) {
                                    // Bars container
                                    HStack(alignment: .bottom, spacing: 4) {
                                        ForEach(Array(selectedMonths.enumerated()), id: \.offset) { monthIndex, _ in
                                            let amount = monthlyData.indices.contains(monthIndex) ? (monthlyData[monthIndex][category.name] ?? 0) : 0
                                            let normalizedHeight = safeMaxAmount > 0 ? amount / safeMaxAmount : 0
                                            // Calculate bar height using precise percentage approach
                                            let percentage = safeMaxAmount > 0 ? amount / safeMaxAmount : 0
                                            let maxBarHeight = chartHeight - 20 // Max height aligns with top gridline
                                            let adjustedBarHeight = max(CGFloat(percentage) * maxBarHeight, 2.0)

                                            Rectangle()
                                                .fill(getColorForMonth(index: monthIndex))
                                                .frame(width: getBarWidth(), height: adjustedBarHeight)
                                                .cornerRadius(2)
                                        }
                                    }
                                    .frame(height: chartHeight, alignment: .bottom)

                                    // Category label
                                    Text(category.name.count > 17 ? String(category.name.prefix(17)) + "..." : category.name)
                                        .font(.caption2)
                                        .foregroundColor(.colSecondaryText)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                }
                                .frame(width: categoryWidth)

                                // Add spacing after each category except the last
                                if index < categories.count - 1 {
                                    Spacer()
                                        .frame(width: getSpacingAfterCategory(category.name))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        )
    }

    private func getColorForMonth(index: Int) -> Color {
        let colors: [Color] = [
            Color.blue,
            Color.green,
            Color.orange,
            Color.purple,
            Color.red,
            Color.cyan
        ]
        return colors.indices.contains(index) ? colors[index] : Color.gray
    }
    private func getCategoryWidth(for categoryName: String) -> CGFloat {
        let nameLength = categoryName.count
        let monthCount = selectedMonths.count

        // Calculate bar width needed: number of months * bar width + spacing between bars
        let barsWidth = CGFloat(monthCount) * getBarWidth() + CGFloat(max(0, monthCount - 1)) * 4

        if nameLength <= 17 {
            // Base width + extra width based on character count, but ensure it fits the bars
            let textBasedWidth = max(60 + CGFloat(nameLength) * 4, 80)
            return max(textBasedWidth, barsWidth + 10) // Add 10px padding around bars
        } else {
            // Fixed width for truncated names, but ensure it fits the bars
            return max(100, barsWidth + 10)
        }
    }

    private func getSpacingAfterCategory(_ categoryName: String) -> CGFloat {
        let nameLength = categoryName.count
        let monthCount = selectedMonths.count

        // Increase spacing when there are more months to prevent crowding
        let baseSpacing: CGFloat = monthCount > 4 ? 16 : 8

        if nameLength <= 17 {
            // Less spacing for longer names to fit them better, but more when many months
            return max(baseSpacing, (monthCount > 4 ? 32 : 24) - CGFloat(nameLength))
        } else {
            return baseSpacing
        }
    }

    private func getBarWidth() -> CGFloat {
        let monthCount = selectedMonths.count
        // Reduce bar width when there are many months to prevent overlap
        switch monthCount {
        case 1...3: return 18
        case 4: return 16
        case 5: return 14
        case 6: return 12
        default: return 10
        }
    }
}

// MARK: - Month Selection View
struct MonthSelectionView: View {
    @Binding var selectedMonths: [Date]
    @Environment(\.dismiss) private var dismiss
    @State private var showingLimitAlert = false

    private var availableMonths: [Date] {
        // Generate last 12 months for selection
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: now)
        }.compactMap { date in
            calendar.dateInterval(of: .month, for: date)?.start
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Clear all filters option
                    Button(action: {
                        selectedMonths = []
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

                            Text("Clear All Selections")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            if selectedMonths.isEmpty {
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

                    ForEach(Array(availableMonths.enumerated()), id: \.element) { index, month in
                        VStack(spacing: 0) {
                            Button(action: {
                                toggleMonth(month)
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.colAccent.opacity(0.15))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "calendar")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.colAccent)
                                    }

                                    Text(month.formatted(.dateTime.month(.wide).year()))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)

                                    Spacer()

                                    if isSelected(month) {
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
                            if index < availableMonths.count - 1 {
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
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Select Months")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Max Months Reached", isPresented: $showingLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You can select up to 6 months for comparison.")
        }
    }

    private func isSelected(_ month: Date) -> Bool {
        selectedMonths.contains(month)
    }

    private func toggleMonth(_ month: Date) {
        if isSelected(month) {
            selectedMonths.removeAll { $0 == month }
        } else if selectedMonths.count < 6 {
            selectedMonths.append(month)
            selectedMonths.sort(by: >)
        } else {
            showingLimitAlert = true
        }
    }
}

// MARK: - Category Filter View
struct CategoryFilterView: View {
    let allCategories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Clear all filters option
                    Button(action: {
                        selectedCategories.removeAll()
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

                    ForEach(Array(allCategories.sorted().enumerated()), id: \.element) { index, category in
                        VStack(spacing: 0) {
                            Button(action: {
                                toggleCategory(category)
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.colAccent.opacity(0.15))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "tag")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.colAccent)
                                    }

                                    Text(category)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)

                                    Spacer()

                                    if selectedCategories.contains(category) {
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
                            if index < allCategories.count - 1 {
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
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Filter by Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CompareView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BudgetDataManager()
        return CompareView(dataManager: dataManager)
            .previewDisplayName("Compare View")
    }
}
#endif
