import SwiftUI

// MARK: - Recurring Expenses View
struct RecurringExpensesView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Recurring Expenses")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.colPrimaryText)

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.colSecondaryText)
                }
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(dataManager.recurringExpenses) { recurring in
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

                                Text(recurring.amount.formattedCurrency())
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.colPrimaryText)
                            }

                            Divider()

                            // Recurrence details
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "repeat")
                                        .foregroundColor(.colAccent)
                                    Text("Type:")
                                        .foregroundColor(.colSecondaryText)
                                    Text(recurring.recurrenceType.displayText)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)
                                }
                                .font(.subheadline)

                                if let dayOfWeek = recurring.selectedDayOfWeek {
                                    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.colAccent)
                                        Text("Day:")
                                            .foregroundColor(.colSecondaryText)
                                        Text(days[dayOfWeek - 1])
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }
                                    .font(.subheadline)
                                }

                                if let dayOfMonth = recurring.selectedDayOfMonth {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.colAccent)
                                        Text("Day of Month:")
                                            .foregroundColor(.colSecondaryText)
                                        Text("\(dayOfMonth)")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }
                                    .font(.subheadline)
                                }

                                if let month = recurring.selectedMonthOfYear {
                                    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.colAccent)
                                        Text("Month:")
                                            .foregroundColor(.colSecondaryText)
                                        Text(months[month - 1])
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }
                                    .font(.subheadline)
                                }

                                if let time = recurring.selectedTime {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.colAccent)
                                        Text("Time:")
                                            .foregroundColor(.colSecondaryText)
                                        Text(formatTime(time))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)
                                    }
                                    .font(.subheadline)
                                }

                                HStack {
                                    Image(systemName: recurring.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(recurring.isActive ? .green : .red)
                                    Text("Status:")
                                        .foregroundColor(.colSecondaryText)
                                    Text(recurring.isActive ? "Active" : "Inactive")
                                        .fontWeight(.semibold)
                                        .foregroundColor(recurring.isActive ? .green : .red)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colCardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.colBackground.ignoresSafeArea())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
