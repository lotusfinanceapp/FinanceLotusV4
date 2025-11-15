import SwiftUI

// MARK: - Recurring Expenses Management View
struct RecurringExpensesManagementView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var recurringToDelete: RecurringExpense?
    @State private var showingDeleteConfirmation = false
    @State private var showingAddRecurring = false
    @State private var selectedRecurring: RecurringExpense?

    // Filter out single-time expenses - only show truly recurring ones
    var actualRecurringExpenses: [RecurringExpense] {
        dataManager.recurringExpenses.filter { $0.recurrenceType != .singleTime }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                VStack(spacing: 20) {
                    if actualRecurringExpenses.isEmpty {
                        // Empty state
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "repeat.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.colSecondaryText.opacity(0.5))

                            Text("No Recurring Expenses")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Text("Log an expense with a recurring schedule to see it here")
                                .font(.subheadline)
                                .foregroundColor(.colSecondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Top spacing
                                Color.clear.frame(height: 20)

                                LazyVStack(spacing: 15) {
                                    ForEach(actualRecurringExpenses) { recurring in
                                        RecurringExpenseCard(
                                            recurring: recurring,
                                            onDelete: {
                                                recurringToDelete = recurring
                                                showingDeleteConfirmation = true
                                            },
                                            onToggle: {
                                                dataManager.toggleRecurringExpense(recurring)
                                            }
                                        )
                                        .onTapGesture {
                                            selectedRecurring = recurring
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Manage Recurring")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecurring = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRecurring) {
            AddRecurringExpenseView(dataManager: dataManager, isPresented: $showingAddRecurring)
        }
        .fullScreenCover(item: $selectedRecurring) { recurring in
            RecurringTransactionDetailView(recurringExpense: recurring, dataManager: dataManager)
        }
        .alert("Delete Recurring Expense", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let recurring = recurringToDelete {
                    dataManager.deleteRecurringExpense(recurring)
                }
            }
        } message: {
            Text("Are you sure you want to delete this recurring expense? This will not delete expenses already logged.")
        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Recurring Expense Card
struct RecurringExpenseCard: View {
    let recurring: RecurringExpense
    let onDelete: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recurring.effectiveCategory.icon)
                    .font(.title2)
                    .foregroundColor(recurring.effectiveCategory.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recurring.note.isEmpty ? "Uncategorized" : recurring.note)
                        .font(.headline)
                        .foregroundColor(.colPrimaryText)

                    Text(recurring.effectiveCategory.name)
                        .font(.subheadline)
                        .foregroundColor(.colSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(recurring.amount.formattedCurrency())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    HStack(spacing: 8) {
                        // Toggle active/inactive
                        Button(action: onToggle) {
                            Image(systemName: recurring.isActive ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(recurring.isActive ? .orange : .green)
                        }

                        // Delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Divider()

            // Recurrence details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: recurring.recurrenceType.icon)
                        .foregroundColor(.colAccent)
                    Text(recurring.recurrenceType.displayText)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)

                    Spacer()

                    Text(recurring.isActive ? "Active" : "Paused")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.colOnAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(recurring.isActive ? Color.green : Color.orange)
                        )
                }
                .font(.subheadline)

                // Show specific schedule details
                if let dayOfWeek = recurring.selectedDayOfWeek {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.colAccent)
                        Text("Every \(formatDayOfWeek(dayOfWeek))")
                            .foregroundColor(.colSecondaryText)
                    }
                    .font(.subheadline)
                }

                if let dayOfMonth = recurring.selectedDayOfMonth {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.colAccent)
                        Text("Every \(formatDayOfMonth(dayOfMonth)) of the month")
                            .foregroundColor(.colSecondaryText)
                    }
                    .font(.subheadline)
                }

                if let month = recurring.selectedMonthOfYear {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.colAccent)
                        Text("Every \(formatMonth(month))")
                            .foregroundColor(.colSecondaryText)
                    }
                    .font(.subheadline)
                }

                if let time = recurring.selectedTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.colAccent)
                        Text("At \(formatTime(time))")
                            .foregroundColor(.colSecondaryText)
                    }
                    .font(.subheadline)
                }

                if let date = recurring.selectedDate, recurring.recurrenceType == .singleTime {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.colAccent)
                        Text("On \(formatDate(date))")
                            .foregroundColor(.colSecondaryText)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .opacity(recurring.isActive ? 1.0 : 0.6)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatDayOfWeek(_ dayOfWeek: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek - 1]
    }

    private func formatDayOfMonth(_ day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    private func formatMonth(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
