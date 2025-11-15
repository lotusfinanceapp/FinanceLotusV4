import SwiftUI

// MARK: - Budget Overview Card Component
struct BudgetOverviewCard: View {
    @ObservedObject var dataManager: BudgetDataManager
    let showElements: Bool

    private var budgetAmount: Double {
        dataManager.budget?.amount ?? 1
    }

    private var percentage: Double {
        min(dataManager.totalSpent / budgetAmount, 1.0)
    }

    private var percentageText: String {
        String(format: "%.1f%%", percentage * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
                // Top row: Icon, Amount, and Arrow
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple.opacity(0.8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(dataManager.totalSpent.formattedCurrency()) / \(budgetAmount.formattedCurrency())")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.colPrimaryText)

                        Text("For this month")
                            .font(.system(size: 12))
                            .foregroundColor(.colSecondaryText)
                            .padding(.bottom, 6)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                }

                VStack(spacing: 6) {
                    // Progress bar with percentage bubble
                    GeometryReader { barGeometry in
                        let actualBarWidth = barGeometry.size.width
                        let actualFillWidth = actualBarWidth * CGFloat(percentage)
                        let arrowWidth: CGFloat = 8
                        let bubbleX = actualFillWidth - (arrowWidth / 2) + 2

                        ZStack(alignment: .topLeading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: actualBarWidth, height: 8)

                            // Filled progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.pink.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: showElements ? actualFillWidth : 0, height: 8)
                                .animation(showElements ? .easeOut(duration: 0.8).delay(0.4) : nil, value: showElements)

                            // Percentage bubble with arrow
                            if showElements {
                                VStack(spacing: 0) {
                                    Text(percentageText)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.colOnAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.black)
                                        .cornerRadius(8)

                                    // Down arrow (triangle)
                                    Triangle()
                                        .fill(Color.black)
                                        .frame(width: 8, height: 4)
                                }
                                .position(x: bubbleX, y: -14)
                                .opacity(showElements ? 1.0 : 0.0)
                                .animation(showElements ? .easeOut(duration: 0.5).delay(0.6) : nil, value: showElements)
                            }
                        }
                    }
                    .frame(height: 8)

                    // Date labels
                    DateLabelsView(dataManager: dataManager)
                        .padding(.top, 6)
                }
        }
        .padding(20)
        .frame(height: 140)
    }
}

// MARK: - Date Labels View
struct DateLabelsView: View {
    @ObservedObject var dataManager: BudgetDataManager

    var body: some View {
        HStack {
            if let budget = dataManager.budget {
                let calendar = Calendar.current
                let now = Date()

                let dates = getPeriodDates(for: budget.period, calendar: calendar, now: now)

                Text(dates.start, style: .date)
                    .font(.system(size: 13))
                    .foregroundColor(.colSecondaryText)

                Spacer()

                Text(dates.end, style: .date)
                    .font(.system(size: 13))
                    .foregroundColor(.colSecondaryText)
            }
        }
    }

    private func getPeriodDates(for period: BudgetPeriod, calendar: Calendar, now: Date) -> (start: Date, end: Date) {
        let start: Date
        let end: Date

        switch period {
        case .daily:
            start = calendar.startOfDay(for: now)
            end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        case .weekly:
            start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
        case .monthly:
            start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
        case .yearly:
            start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            end = calendar.date(byAdding: .year, value: 1, to: start) ?? now
        }

        return (start, end)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
