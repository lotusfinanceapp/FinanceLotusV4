import SwiftUI

// MARK: - Add Recurring Expense View
struct AddRecurringExpenseView: View {
    @ObservedObject var dataManager: BudgetDataManager
    @Binding var isPresented: Bool
    @ObservedObject var categoryManager = CategoryManager()

    @State private var expenseAmount = ""
    @State private var selectedCategory: CustomCategory?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedRecurrenceType: RecurrenceType = .daily
    @State private var selectedDayOfWeek = Calendar.current.component(.weekday, from: Date())
    @State private var selectedDayOfMonth = Calendar.current.component(.day, from: Date())
    @State private var selectedMonthOfYear = Calendar.current.component(.month, from: Date())
    @State private var selectedTime = Date()
    @State private var showElements = false

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPastCycleAlert = false
    @State private var shouldLogPastCycle = false
    @State private var showingCustomNumberPad = false
    @State private var showingAddSubcategory = false
    @State private var newSubcategoryName = ""

    var body: some View {
        VStack(spacing: 0) {
            // === HEADER SECTION WITH BACK BUTTON ===
            VStack(spacing: 20) {
                // Back button and title
                HStack {
                    Button(action: {
                        hideKeyboard()
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colBackButtonIcon)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5), value: showElements)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Title section
                VStack(spacing: 10) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.colAccent)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)

                    Text("Add Recurring Expense")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    Text("Set up automatic expense tracking")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
            }
            .padding(.bottom, 30)

            // === FORM SECTION ===
            ScrollView {
                VStack(spacing: 25) {
                    // Combined form card
                    VStack(alignment: .leading, spacing: 25) {
                        // Category Selection
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Category")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categoryManager.allCategories) { category in
                                        Button(action: {
                                            hideKeyboard()
                                            withAnimation(.easeInOut(duration: 0.4)) {
                                                // Toggle selection - deselect if already selected
                                                if selectedCategory?.id == category.id {
                                                    selectedCategory = nil
                                                    selectedSubcategory = nil
                                                } else {
                                                    selectedCategory = category
                                                    selectedSubcategory = nil
                                                }
                                            }
                                        }) {
                                            VStack(spacing: 5) {
                                                Image(systemName: category.icon)
                                                    .font(.title2)
                                                    .foregroundColor(selectedCategory?.id == category.id ? .white : category.color)
                                                    .frame(height: 24)

                                                Text(category.name.count > 12 ? String(category.name.prefix(12)) + "..." : category.name)
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(selectedCategory?.id == category.id ? .white : .colPrimaryText)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(1)
                                                    .frame(height: 14)
                                            }
                                            .frame(width: 81, height: 60)
                                            .padding(.vertical, 7)
                                            .padding(.horizontal, 3)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedCategory?.id == category.id ? category.color : category.color.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedCategory?.id == category.id ? category.color : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }

                        // Subcategory Selection (if category selected)
                        if let category = selectedCategory {
                            let subcategories = categoryManager.getSubcategories(for: category)
                            if !subcategories.isEmpty {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Subcategory")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(subcategories) { subcategory in
                                                Button(action: {
                                                    hideKeyboard()
                                                    withAnimation(.easeInOut(duration: 0.4)) {
                                                        // Toggle subcategory - deselect if already selected
                                                        if selectedSubcategory?.id == subcategory.id {
                                                            selectedSubcategory = nil
                                                        } else {
                                                            selectedSubcategory = subcategory
                                                            if let defaultAmount = subcategory.defaultAmount {
                                                                expenseAmount = String(format: "%.2f", defaultAmount)
                                                            }
                                                        }
                                                    }
                                                }) {
                                                    VStack(spacing: 5) {
                                                        Image(systemName: "tag.fill")
                                                            .font(.title2)
                                                            .foregroundColor(selectedSubcategory?.id == subcategory.id ? .white : category.color)
                                                            .frame(height: 24)

                                                        Text(subcategory.name.count > 12 ? String(subcategory.name.prefix(12)) + "..." : subcategory.name)
                                                            .font(.caption2)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(selectedSubcategory?.id == subcategory.id ? .white : .colPrimaryText)
                                                            .multilineTextAlignment(.center)
                                                            .lineLimit(1)
                                                            .frame(height: 14)
                                                    }
                                                    .frame(width: 81, height: 60)
                                                    .padding(.vertical, 7)
                                                    .padding(.horizontal, 3)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(selectedSubcategory?.id == subcategory.id ? category.color : category.color.opacity(0.1))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedSubcategory?.id == subcategory.id ? category.color : Color.clear, lineWidth: 2)
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }

                                            // Add New Subcategory Button
                                            Button(action: {
                                                hideKeyboard()
                                                if let category = selectedCategory {
                                                    showingAddSubcategory = true
                                                }
                                            }) {
                                                VStack(spacing: 5) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.title2)
                                                        .foregroundColor(.colAccent)
                                                        .frame(height: 24)

                                                    Text("Add New")
                                                        .font(.caption2)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.colAccent)
                                                        .multilineTextAlignment(.center)
                                                        .lineLimit(2)
                                                        .frame(height: 14)
                                                }
                                                .frame(width: 81, height: 60)
                                                .padding(.vertical, 7)
                                                .padding(.horizontal, 3)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.colAccent.opacity(0.1))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.colAccent.opacity(0.3), lineWidth: 1.5)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }

                        // Amount Input
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Amount \(String.currencySymbol())")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Button(action: {
                                showingCustomNumberPad = true
                            }) {
                                HStack {
                                    Text(String.currencySymbol())
                                        .font(.body)
                                        .foregroundColor(.colSecondaryText)

                                    Text(expenseAmount.isEmpty ? "0.00" : expenseAmount)
                                        .font(.body)
                                        .foregroundColor(.colPrimaryText)

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.colInputBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.colIconPrimary.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Recurrence Type
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recurrence")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Picker("Recurrence", selection: $selectedRecurrenceType) {
                                Text("Daily").tag(RecurrenceType.daily)
                                Text("Weekly").tag(RecurrenceType.weekly)
                                Text("Monthly").tag(RecurrenceType.monthly)
                                Text("Yearly").tag(RecurrenceType.yearly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .accentColor(.colAccent)
                            .colorScheme(.light)
                        }

                        // Scheduling Options
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Schedule")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            switch selectedRecurrenceType {
                            case .daily:
                                VStack(spacing: 12) {
                                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .colorScheme(.light)
                                        .accentColor(.black)

                                    // Information message for daily
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)

                                        Text("This expense will be logged every day at \(formatTime(selectedTime))")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.colAccent.opacity(0.1))
                                    .cornerRadius(8)
                                }

                            case .weekly:
                                VStack(spacing: 12) {
                                    Picker("Day of Week", selection: $selectedDayOfWeek) {
                                        Text("Sunday").tag(1)
                                        Text("Monday").tag(2)
                                        Text("Tuesday").tag(3)
                                        Text("Wednesday").tag(4)
                                        Text("Thursday").tag(5)
                                        Text("Friday").tag(6)
                                        Text("Saturday").tag(7)
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .colorScheme(.light)

                                    // Information message for weekly
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)

                                        Text("This expense will be logged every \(formatDayOfWeek(selectedDayOfWeek)) at 12:00 PM")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.colAccent.opacity(0.1))
                                    .cornerRadius(8)
                                }


                            case .monthly:
                                VStack(spacing: 12) {
                                    Picker("Day of Month", selection: $selectedDayOfMonth) {
                                        ForEach(1...31, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .colorScheme(.light)

                                    // Information message for monthly
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)

                                        Text("This expense will be logged on the \(formatDayOfMonth(selectedDayOfMonth)) of every month")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.colAccent.opacity(0.1))
                                    .cornerRadius(8)

                                    // Warning for day 31
                                    if selectedDayOfMonth == 31 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)

                                            Text("Months with fewer than 31 days will be logged on the last day of the month")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }

                                    // Warning for day 30
                                    if selectedDayOfMonth == 30 {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)

                                            Text("February will be logged on the last day of the month (28th or 29th)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }

                            case .yearly:
                                VStack(spacing: 12) {
                                    Picker("Month", selection: $selectedMonthOfYear) {
                                        Text("January").tag(1)
                                        Text("February").tag(2)
                                        Text("March").tag(3)
                                        Text("April").tag(4)
                                        Text("May").tag(5)
                                        Text("June").tag(6)
                                        Text("July").tag(7)
                                        Text("August").tag(8)
                                        Text("September").tag(9)
                                        Text("October").tag(10)
                                        Text("November").tag(11)
                                        Text("December").tag(12)
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .colorScheme(.light)

                                    // Information message for yearly
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)

                                        Text("This expense will be logged on the 1st of \(formatMonth(selectedMonthOfYear)) every year")
                                            .font(.caption)
                                            .foregroundColor(.colAccent)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.colAccent.opacity(0.1))
                                    .cornerRadius(8)
                                }

                            case .singleTime:
                                EmptyView()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 25)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 30)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)

                    // Add button at bottom
                    Button(action: {
                        hideKeyboard()
                        addRecurringExpense()
                    }) {
                        Text("Add Recurring Expense")
                            .font(.headline)
                            .foregroundColor(.colOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(expenseAmount.isEmpty || selectedCategory == nil)
                    .opacity((expenseAmount.isEmpty || selectedCategory == nil) ? 0.6 : 1.0)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showElements)

                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            showElements = false
            selectedCategory = categoryManager.allCategories.first
            withAnimation {
                showElements = true
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Past Cycle Detected", isPresented: $showingPastCycleAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Skip This Cycle") {
                createRecurringExpense(logPastCycle: false)
            }
            Button("Log for This Cycle") {
                createRecurringExpense(logPastCycle: true)
            }
        } message: {
            Text("This cycle's scheduled time has already passed. Would you like to log an expense for this cycle anyway?")
        }
        .overlay(
            Group {
                if showingCustomNumberPad {
                    CustomNumberPad(
                        text: $expenseAmount,
                        isPresented: $showingCustomNumberPad,
                        onDismiss: {}
                    )
                }
            }
        )
        .sheet(isPresented: $showingAddSubcategory, onDismiss: {
            newSubcategoryName = ""
        }) {
            if let category = selectedCategory {
                AddSubcategorySheet(
                    category: category,
                    subcategoryName: $newSubcategoryName,
                    onAdd: { amount in
                        if !newSubcategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let defaultAmount = Double(amount)
                            categoryManager.addSubcategory(to: category, subcategoryName: newSubcategoryName.trimmingCharacters(in: .whitespaces), defaultAmount: defaultAmount)

                            // Find and select the newly created subcategory
                            let updatedSubcategories = categoryManager.getSubcategories(for: category)
                            if let newSubcategory = updatedSubcategories.first(where: { $0.name == newSubcategoryName.trimmingCharacters(in: .whitespaces) }) {
                                selectedSubcategory = newSubcategory
                            }

                            newSubcategoryName = ""
                            showingAddSubcategory = false
                        }
                    },
                    isPresented: $showingAddSubcategory
                )
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func formatDayOfWeek(_ dayOfWeek: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayOfWeek - 1]
    }

    private func formatMonth(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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

    private func addRecurringExpense() {
        // Validate amount
        guard let amount = Double(expenseAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount greater than $0"
            showingAlert = true
            return
        }

        // Validate category
        guard let category = selectedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            return
        }

        // Check if the cycle has already passed
        if hasCyclePassed() {
            showingPastCycleAlert = true
            return
        }

        // Proceed with creating the recurring expense
        createRecurringExpense(logPastCycle: false)
    }

    private func hasCyclePassed() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRecurrenceType {
        case .singleTime:
            return false // Not applicable for one-time expenses

        case .daily:
            // Check if today's scheduled time has already passed
            if let selectedTime = selectedTime as Date? {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                let currentComponents = calendar.dateComponents([.hour, .minute], from: now)

                let scheduledMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
                let currentMinutes = (currentComponents.hour ?? 0) * 60 + (currentComponents.minute ?? 0)

                return currentMinutes > scheduledMinutes
            }
            return false

        case .weekly:
            // Check if this week's selected day has passed, or if it's today but past noon
            let currentDayOfWeek = calendar.component(.weekday, from: now)
            if currentDayOfWeek > selectedDayOfWeek {
                return true
            } else if currentDayOfWeek == selectedDayOfWeek {
                let currentHour = calendar.component(.hour, from: now)
                return currentHour >= 12
            }
            return false

        case .monthly:
            // Check if this month's selected day has passed, or if it's today but past noon
            let currentDayOfMonth = calendar.component(.day, from: now)
            if currentDayOfMonth > selectedDayOfMonth {
                return true
            } else if currentDayOfMonth == selectedDayOfMonth {
                let currentHour = calendar.component(.hour, from: now)
                return currentHour >= 12
            }
            return false

        case .yearly:
            // Check if this year's selected month has passed, or if it's this month's 1st but past noon
            let currentMonth = calendar.component(.month, from: now)
            let currentDay = calendar.component(.day, from: now)
            if currentMonth > selectedMonthOfYear {
                return true
            } else if currentMonth == selectedMonthOfYear {
                if currentDay > 1 {
                    return true
                } else if currentDay == 1 {
                    let currentHour = calendar.component(.hour, from: now)
                    return currentHour >= 12
                }
            }
            return false
        }
    }

    private func createRecurringExpense(logPastCycle: Bool) {
        guard let amount = Double(expenseAmount), amount > 0,
              let category = selectedCategory else {
            return
        }

        // Use subcategory name as note if selected, otherwise empty
        let note = selectedSubcategory?.name ?? ""

        // Create recurring expense
        var recurringExpense = RecurringExpense(
            amount: amount,
            note: note,
            customCategory: category,
            recurrenceType: selectedRecurrenceType,
            selectedDate: nil,
            selectedTime: selectedRecurrenceType == .daily ? selectedTime : nil,
            selectedDayOfWeek: selectedRecurrenceType == .weekly ? selectedDayOfWeek : nil,
            selectedDayOfMonth: selectedRecurrenceType == .monthly ? selectedDayOfMonth : nil,
            selectedMonthOfYear: selectedRecurrenceType == .yearly ? selectedMonthOfYear : nil
        )

        // Add the recurring expense first so we have its ID
        dataManager.addRecurringExpense(recurringExpense)

        // If user chose to log past cycle, create the expense for the scheduled time
        // and link it to the recurring expense
        if logPastCycle {
            let scheduledDate = getScheduledDateForCurrentCycle()
            dataManager.addExpense(amount, note: note, customCategory: category, date: scheduledDate, recurringExpenseId: recurringExpense.id)

            // Mark this cycle as already processed to prevent duplicate logging
            // when processRecurringExpenses() runs
            if let index = dataManager.recurringExpenses.firstIndex(where: { $0.id == recurringExpense.id }) {
                dataManager.recurringExpenses[index].lastProcessedDate = scheduledDate
                dataManager.saveData()
            }
        }

        // Success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Close sheet
        isPresented = false
    }

    private func getScheduledDateForCurrentCycle() -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRecurrenceType {
        case .singleTime:
            return now

        case .daily:
            // Return today at the selected time
            if let selectedTime = selectedTime as Date? {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: now) ?? now
            }
            return now

        case .weekly:
            // Return this week's selected day at 12:00 PM
            let currentWeekday = calendar.component(.weekday, from: now)
            let daysToSubtract = currentWeekday - selectedDayOfWeek
            if let targetDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) {
                return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: targetDate) ?? now
            }
            return now

        case .monthly:
            // Return this month's selected day at 12:00 PM
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            var components = DateComponents()
            components.year = currentYear
            components.month = currentMonth
            components.day = selectedDayOfMonth
            components.hour = 12
            components.minute = 0
            return calendar.date(from: components) ?? now

        case .yearly:
            // Return this year's selected month, 1st day at 12:00 PM
            let currentYear = calendar.component(.year, from: now)
            var components = DateComponents()
            components.year = currentYear
            components.month = selectedMonthOfYear
            components.day = 1
            components.hour = 12
            components.minute = 0
            return calendar.date(from: components) ?? now
        }
    }
}
