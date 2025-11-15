import SwiftUI

// MARK: - Expense Detail Presentation Wrapper
struct ExpenseDetailPresentation: Identifiable {
    let id = UUID()
    let expense: Expense
    let startInEditMode: Bool
}

// MARK: - Expense Row View
struct ExpenseRowView: View {
    let expense: Expense
    let dataManager: BudgetDataManager
    @Binding var expenseDetailPresentation: ExpenseDetailPresentation?
    @Binding var selectedCategoryForDetail: CustomCategory?
    @Binding var showingCategoryDetail: Bool
    let isEditMode: Bool
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 16) {
            // Delete button (only visible in edit mode)
            if isEditMode {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        deleteExpense()
                    }

                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 32, height: 32)

                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.colOnAccent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isEditMode ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isEditMode)
            }

            // Category icon
            ZStack {
                Circle()
                    .fill(expense.effectiveCategory.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: expense.effectiveCategory.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(expense.effectiveCategory.color)

                // Recurring expense indicator badge
                if expense.recurringExpenseId != nil {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.colAccent)
                        .opacity(0.7)
                        .background(
                            Circle()
                                .fill(Color.colCardBackground)
                                .frame(width: 10, height: 10)
                        )
                        .offset(x: 11, y: -11)
                }
            }

            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                Text({
                    let text = expense.note.isEmpty ? "Untitled" : expense.note
                    return text.count > 25 ? String(text.prefix(25)) + "..." : text
                }())
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.colPrimaryText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text({
                        let categoryName = expense.effectiveCategory.name
                        if isEditMode && categoryName.count > 12 {
                            return String(categoryName.prefix(9)) + "..."
                        }
                        return categoryName
                    }())
                        .font(.caption)
                        .foregroundColor(expense.effectiveCategory.color)
                        .lineLimit(1)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText.opacity(0.5))

                    Text(expense.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }
            }

            Spacer()

            // Amount
            Text(expense.amount.formattedCurrency())
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.colPrimaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.colBackground)
        .offset(x: shakeOffset)
        .onTapGesture {
            print("DEBUG: ExpenseRowView tapped - isEditMode: \(isEditMode)")
            expenseDetailPresentation = ExpenseDetailPresentation(
                expense: expense,
                startInEditMode: isEditMode
            )
            print("DEBUG: Set expenseDetailPresentation with startInEditMode: \(isEditMode)")
        }
        .onAppear {
            if isEditMode {
                startShakeAnimation()
            }
        }
        .onChange(of: isEditMode) { editMode in
            if editMode {
                startShakeAnimation()
            } else {
                stopShakeAnimation()
            }
        }
    }

    private func startShakeAnimation() {
        withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
            shakeOffset = 1.5
        }
    }

    private func stopShakeAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            shakeOffset = 0
        }
    }

    private func deleteExpense() {
        dataManager.deleteExpense(expense)
    }
}
