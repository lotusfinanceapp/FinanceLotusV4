import SwiftUI

// MARK: - Analytics Screen - PLACEHOLDER
struct AnalyticsView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @State private var showingSpendingGraph = false
    @State private var showingCompareView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // === TOP SPACING ===
                Color.clear.frame(height: 80) // Space for fixed logo

                // === HEADER SECTION ===
                VStack(spacing: 15) {
                    // Analytics icon
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.colChartIcon)

                    // Main heading
                    Text("Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    Text("Coming Soon")
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                }

                // === PLACEHOLDER CONTENT ===
                VStack(spacing: 20) {
                    Text("Advanced analytics and insights will be available here")
                        .font(.body)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Placeholder cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(0..<4, id: \.self) { index in
                            Button(action: {
                                if index == 0 { // Trends card
                                    showingSpendingGraph = true
                                } else if index == 1 { // Comparisons card
                                    showingCompareView = true
                                }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: placeholderIcon(for: index))
                                        .font(.system(size: 24))
                                        .foregroundColor(index == 0 || index == 1 ? .colAccent : .colAccent.opacity(0.6))

                                    Text(placeholderTitle(for: index))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)

                                    Text(placeholderSubtitle(for: index))
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(index == 0 || index == 1 ? Color.colCardBackground : Color.colCardBackground.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(index == 0 || index == 1 ? Color.colAccent.opacity(0.4) : Color.colAccent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(index != 0 && index != 1) // Only Trends and Comparisons cards are clickable
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Add bottom padding for safe scrolling
                Color.clear.frame(height: 100)
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.container, edges: .top))
        .sheet(isPresented: $showingSpendingGraph) {
            SpendingGraphView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingCompareView) {
            CompareView(dataManager: dataManager)
        }
    }

    private func placeholderIcon(for index: Int) -> String {
        switch index {
        case 0: return "chart.line.uptrend.xyaxis"
        case 1: return "chart.bar.xaxis"
        case 2: return "chart.pie"
        case 3: return "target"
        default: return "chart.bar.fill"
        }
    }

    private func placeholderTitle(for index: Int) -> String {
        switch index {
        case 0: return "Trends"
        case 1: return "Comparisons"
        case 2: return "Breakdowns"
        case 3: return "Goals"
        default: return "Analytics"
        }
    }

    private func placeholderSubtitle(for index: Int) -> String {
        switch index {
        case 0: return "Spending patterns over time"
        case 1: return "Month-to-month analysis"
        case 2: return "Category distributions"
        case 3: return "Budget targets & forecasts"
        default: return "Coming soon"
        }
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