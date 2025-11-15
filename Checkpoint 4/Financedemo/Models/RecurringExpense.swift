import Foundation

// MARK: - Recurring Expense Models
enum RecurrenceType: String, CaseIterable, Codable {
    case singleTime = "Single-time"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var icon: String {
        switch self {
        case .singleTime:
            return "1.circle.fill"
        case .daily:
            return "calendar.circle.fill"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar"
        case .yearly:
            return "calendar.badge.plus"
        }
    }

    var description: String {
        switch self {
        case .singleTime:
            return "One-time expense"
        case .daily:
            return "Repeats every day"
        case .weekly:
            return "Repeats every week"
        case .monthly:
            return "Repeats every month"
        case .yearly:
            return "Repeats every year"
        }
    }

    var displayText: String {
        switch self {
        case .singleTime:
            return "One-time"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
}

struct RecurringExpense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let note: String
    let category: ExpenseCategory?
    let customCategory: CustomCategory?
    let recurrenceType: RecurrenceType
    let startDate: Date
    let createdDate: Date
    var isActive: Bool
    var lastProcessedDate: Date?

    // Specific scheduling details
    let selectedDate: Date? // For single-time (specific date)
    let selectedTime: Date? // For daily (specific time of day)
    let selectedDayOfWeek: Int? // For weekly (1=Sunday, 7=Saturday)
    let selectedDayOfMonth: Int? // For monthly (1-31)
    let selectedMonthOfYear: Int? // For yearly (1-12)

    init(amount: Double, note: String, category: ExpenseCategory? = nil, customCategory: CustomCategory? = nil, recurrenceType: RecurrenceType, startDate: Date = Date(), selectedDate: Date? = nil, selectedTime: Date? = nil, selectedDayOfWeek: Int? = nil, selectedDayOfMonth: Int? = nil, selectedMonthOfYear: Int? = nil) {
        self.id = UUID() // Generate ID only on creation
        self.amount = amount
        self.note = note
        self.category = category
        self.customCategory = customCategory
        self.recurrenceType = recurrenceType
        self.startDate = startDate
        self.createdDate = Date()
        self.isActive = true
        self.lastProcessedDate = nil
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.selectedDayOfWeek = selectedDayOfWeek
        self.selectedDayOfMonth = selectedDayOfMonth
        self.selectedMonthOfYear = selectedMonthOfYear
    }

    // Init for updating existing recurring expense (preserves ID and other metadata)
    init(id: UUID, amount: Double, note: String, category: ExpenseCategory?, customCategory: CustomCategory?, recurrenceType: RecurrenceType, startDate: Date, createdDate: Date, isActive: Bool, lastProcessedDate: Date?, selectedDate: Date?, selectedTime: Date?, selectedDayOfWeek: Int?, selectedDayOfMonth: Int?, selectedMonthOfYear: Int?) {
        self.id = id // Preserve existing ID
        self.amount = amount
        self.note = note
        self.category = category
        self.customCategory = customCategory
        self.recurrenceType = recurrenceType
        self.startDate = startDate
        self.createdDate = createdDate
        self.isActive = isActive
        self.lastProcessedDate = lastProcessedDate
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.selectedDayOfWeek = selectedDayOfWeek
        self.selectedDayOfMonth = selectedDayOfMonth
        self.selectedMonthOfYear = selectedMonthOfYear
    }

    var effectiveCategory: CustomCategory {
        return customCategory ?? CustomCategory.fromExpenseCategory(category ?? .other)
    }

    // Calculate next occurrence date
    func nextOccurrenceAfter(date: Date) -> Date? {
        guard isActive else { return nil }

        let calendar = Calendar.current
        let now = date

        switch recurrenceType {
        case .singleTime:
            return lastProcessedDate == nil ? startDate : nil

        case .daily:
            // For daily, next occurrence is tomorrow at the selected time
            if let selectedTime = selectedTime {
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute

                if let todayAtTime = calendar.date(from: components) {
                    // If today's time hasn't passed, return today; otherwise tomorrow
                    if todayAtTime > now {
                        return todayAtTime
                    } else {
                        return calendar.date(byAdding: .day, value: 1, to: todayAtTime)
                    }
                }
            }
            return calendar.date(byAdding: .day, value: 1, to: now)

        case .weekly:
            // For weekly, next occurrence is on the selected day of week
            if let targetDayOfWeek = selectedDayOfWeek {
                let currentDayOfWeek = calendar.component(.weekday, from: now)
                var daysToAdd = targetDayOfWeek - currentDayOfWeek

                if daysToAdd <= 0 {
                    daysToAdd += 7 // Move to next week
                }

                return calendar.date(byAdding: .day, value: daysToAdd, to: now)
            }
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)

        case .monthly:
            // For monthly, next occurrence is on the selected day of month
            if let targetDayOfMonth = selectedDayOfMonth {
                let currentDay = calendar.component(.day, from: now)
                var components = calendar.dateComponents([.year, .month], from: now)
                components.day = targetDayOfMonth

                if let nextDate = calendar.date(from: components) {
                    // If this month's day hasn't passed, use this month; otherwise next month
                    if nextDate > now {
                        return nextDate
                    } else {
                        // Add 1 month
                        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: nextDate) {
                            return nextMonth
                        }
                    }
                }
            }
            return calendar.date(byAdding: .month, value: 1, to: now)

        case .yearly:
            // For yearly, next occurrence is on the selected month and day
            if let targetMonth = selectedMonthOfYear, let targetDay = selectedDayOfMonth {
                let currentYear = calendar.component(.year, from: now)
                var components = DateComponents()
                components.year = currentYear
                components.month = targetMonth
                components.day = targetDay

                if let nextDate = calendar.date(from: components) {
                    // If this year's date hasn't passed, use this year; otherwise next year
                    if nextDate > now {
                        return nextDate
                    } else {
                        // Add 1 year
                        components.year = currentYear + 1
                        return calendar.date(from: components)
                    }
                }
            }
            return calendar.date(byAdding: .year, value: 1, to: now)
        }
    }

    // Check if expense should be processed on a given date
    func shouldProcessOn(date: Date) -> Bool {
        guard isActive else { return false }

        let calendar = Calendar.current

        switch recurrenceType {
        case .singleTime:
            // For single-time, check if it matches the selected date (or today if none specified)
            if let targetDate = selectedDate {
                return lastProcessedDate == nil && calendar.isDate(date, inSameDayAs: targetDate)
            }
            return lastProcessedDate == nil && calendar.isDate(date, inSameDayAs: startDate)

        case .daily:
            // For daily, check if we haven't processed today yet
            // Notification system handles timing
            if let lastProcessed = lastProcessedDate {
                // Already processed today, don't process again
                if calendar.isDate(date, inSameDayAs: lastProcessed) {
                    return false
                }
            }

            // Check if today is on or after the start date
            return calendar.isDate(date, inSameDayAs: startDate) || date > startDate

        case .weekly:
            // For weekly, check if today matches the selected day of week
            // Notification system handles timing (12:00 PM)
            if let targetDayOfWeek = selectedDayOfWeek {
                let currentDayOfWeek = calendar.component(.weekday, from: date)
                if currentDayOfWeek != targetDayOfWeek {
                    return false // Not the right day of week
                }
            }
            // Check if we haven't processed this week yet
            if let lastProcessed = lastProcessedDate {
                if calendar.isDate(date, equalTo: lastProcessed, toGranularity: .weekOfYear) {
                    return false
                }
            }
            // Check if date is after start date
            return date >= startDate

        case .monthly:
            // For monthly, check if today matches the selected day of month
            // Notification system handles timing (12:00 PM)
            if let targetDayOfMonth = selectedDayOfMonth {
                let currentDayOfMonth = calendar.component(.day, from: date)
                let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

                // Handle months with fewer days (e.g., Feb 30 -> Feb 28/29, April 31 -> April 30)
                if targetDayOfMonth > daysInMonth {
                    // Log on last day of month if target day doesn't exist
                    if currentDayOfMonth != daysInMonth {
                        return false
                    }
                } else if currentDayOfMonth != targetDayOfMonth {
                    return false // Not the right day of month
                }
            }
            // Check if we haven't processed this month yet
            if let lastProcessed = lastProcessedDate {
                if calendar.isDate(date, equalTo: lastProcessed, toGranularity: .month) {
                    return false
                }
            }
            // Check if date is after start date
            return date >= startDate

        case .yearly:
            // For yearly, check if today matches the 1st of the selected month
            // Notification system handles timing (12:00 PM)
            if let targetMonth = selectedMonthOfYear {
                let currentMonth = calendar.component(.month, from: date)
                let currentDay = calendar.component(.day, from: date)
                if currentMonth != targetMonth || currentDay != 1 {
                    return false // Not the right month or not the 1st day
                }
            }
            // Check if we haven't processed this year yet
            if let lastProcessed = lastProcessedDate {
                if calendar.isDate(date, equalTo: lastProcessed, toGranularity: .year) {
                    return false
                }
            }
            // Check if date is after start date
            return date >= startDate
        }
    }
}