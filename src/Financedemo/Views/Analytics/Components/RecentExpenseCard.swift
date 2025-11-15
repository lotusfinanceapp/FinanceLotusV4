import SwiftUI

// MARK: - Recent Expense Card Component
struct RecentExpenseCard: View {
    let expense: Expense
    let category: CustomCategory

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.amount.formattedCurrency())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)

                    Text(noteText)
                        .font(.caption2)
                        .foregroundColor(.colSecondaryText)
                }

                Spacer()

                Text(formatShortDate(expense.date))
                    .font(.caption2)
                    .foregroundColor(.colSecondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
                .background(Color.colSecondaryText.opacity(0.2))
        }
    }

    // Helper computed properties
    private var noteText: String {
        let text = expense.note.isEmpty ? "Uncategorized" : expense.note
        return text.count > 26 ? String(text.prefix(26)) + "..." : text
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
