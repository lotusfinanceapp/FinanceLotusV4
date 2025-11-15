import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    weak var dataManager: BudgetDataManager?

    override init() {
        super.init()
        checkAuthorizationStatus()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        print("🔔 NotificationManager: Requesting permission from iOS")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("🔔 NotificationManager: Permission response - granted: \(granted), error: \(error?.localizedDescription ?? "none")")
            DispatchQueue.main.async {
                self.isAuthorized = granted
                print("🔔 NotificationManager: isAuthorized set to \(self.isAuthorized)")
            }
        }
    }

    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func checkAuthorizationStatusAndUpdate() {
        print("🔔 NotificationManager: checkAuthorizationStatusAndUpdate called")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let authStatus = settings.authorizationStatus
                print("🔔 NotificationManager: Authorization status = \(authStatus.rawValue)")
                self.isAuthorized = authStatus == .authorized
                print("🔔 NotificationManager: isAuthorized set to \(self.isAuthorized)")
            }
        }
    }

    private func areNotificationsEnabled() -> Bool {
        let systemEnabled = isAuthorized
        let appEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        return systemEnabled && appEnabled
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleExpenseConfirmation(amount: Double, category: String, at date: Date) {
        guard areNotificationsEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Expense Added ✅"
        content.body = "\(String.currencySymbol())\(String(format: "%.2f", amount)) added to \(category)"
        content.sound = .default

        // Calculate time interval from now to the scheduled date
        let timeInterval = date.timeIntervalSinceNow

        // If the date is in the past or very soon (within 1 second), trigger immediately
        let trigger: UNNotificationTrigger
        if timeInterval <= 1 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "expense-confirmation-\(date.timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule expense confirmation notification: \(error.localizedDescription)")
            }
        }
    }

    // Schedule recurring expense notifications
    func scheduleRecurringExpenseNotification(recurringExpense: RecurringExpense) {
        guard areNotificationsEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Expense Added ✅"
        content.body = "\(String.currencySymbol())\(String(format: "%.2f", recurringExpense.amount)) added to \(recurringExpense.effectiveCategory.name)"
        content.sound = .default

        // Add custom data to identify this as a recurring expense notification
        content.userInfo = [
            "type": "recurring-expense",
            "recurringExpenseId": recurringExpense.id.uuidString
        ]

        var trigger: UNNotificationTrigger?

        switch recurringExpense.recurrenceType {
        case .singleTime:
            // Schedule for the specific date/time
            if let selectedDate = recurringExpense.selectedDate {
                let timeInterval = selectedDate.timeIntervalSinceNow
                if timeInterval > 0 {
                    trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                }
            }

        case .daily:
            // Schedule daily at the selected time
            if let selectedTime = recurringExpense.selectedTime {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
                var dateComponents = DateComponents()
                dateComponents.hour = components.hour
                dateComponents.minute = components.minute
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            }

        case .weekly:
            // Schedule weekly on the selected day at 12:00 PM (noon)
            if let dayOfWeek = recurringExpense.selectedDayOfWeek {
                var dateComponents = DateComponents()
                dateComponents.weekday = dayOfWeek
                dateComponents.hour = 12
                dateComponents.minute = 0
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            }

        case .monthly:
            // Schedule monthly on the selected day at 12:00 PM (noon)
            if let dayOfMonth = recurringExpense.selectedDayOfMonth {
                var dateComponents = DateComponents()
                dateComponents.day = dayOfMonth
                dateComponents.hour = 12
                dateComponents.minute = 0
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

                // For days > 28, also schedule for the last day of months that don't have that day
                // This ensures the notification fires even in shorter months
                if dayOfMonth > 28 {
                    // Schedule additional notifications for the last day of shorter months
                    let identifier = "recurring-expense-\(recurringExpense.id.uuidString)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger!)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("⚠️ Failed to schedule monthly notification (day \(dayOfMonth)): \(error.localizedDescription)")
                        }
                    }

                    // Create additional notification for last day of February (28/29)
                    if dayOfMonth > 29 {
                        var febComponents = DateComponents()
                        febComponents.month = 2
                        febComponents.day = 28
                        febComponents.hour = 12
                        febComponents.minute = 0
                        let febTrigger = UNCalendarNotificationTrigger(dateMatching: febComponents, repeats: true)
                        let febRequest = UNNotificationRequest(identifier: "\(identifier)-feb28", content: content, trigger: febTrigger)
                        UNUserNotificationCenter.current().add(febRequest) { error in
                            if let error = error {
                                print("⚠️ Failed to schedule February overflow notification: \(error.localizedDescription)")
                            }
                        }
                    }

                    // Create additional notification for months with 30 days (if day is 31)
                    if dayOfMonth == 31 {
                        // April, June, September, November
                        for month in [4, 6, 9, 11] {
                            var monthComponents = DateComponents()
                            monthComponents.month = month
                            monthComponents.day = 30
                            monthComponents.hour = 12
                            monthComponents.minute = 0
                            let monthTrigger = UNCalendarNotificationTrigger(dateMatching: monthComponents, repeats: true)
                            let monthRequest = UNNotificationRequest(identifier: "\(identifier)-month\(month)", content: content, trigger: monthTrigger)
                            UNUserNotificationCenter.current().add(monthRequest) { error in
                                if let error = error {
                                    print("⚠️ Failed to schedule month \(month) overflow notification: \(error.localizedDescription)")
                                }
                            }
                        }
                    }

                    trigger = nil // Already added, don't add again below
                }
            }

        case .yearly:
            // Schedule yearly on the 1st of the selected month at 12:00 PM (noon)
            if let month = recurringExpense.selectedMonthOfYear {
                var dateComponents = DateComponents()
                dateComponents.month = month
                dateComponents.day = 1 // First day of the month
                dateComponents.hour = 12
                dateComponents.minute = 0
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            }
        }

        if let trigger = trigger {
            let identifier = "recurring-expense-\(recurringExpense.id.uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("⚠️ Failed to schedule recurring expense notification: \(error.localizedDescription)")
                    print("⚠️ Recurring expense: \(recurringExpense.id.uuidString)")
                } else {
                    print("✅ Scheduled recurring expense notification: \(recurringExpense.id.uuidString)")
                }
            }
        }
    }

    // Cancel recurring expense notification
    func cancelRecurringExpenseNotification(recurringExpenseId: UUID) {
        let identifier = "recurring-expense-\(recurringExpenseId.uuidString)"

        // Cancel main notification
        var identifiersToRemove = [identifier]

        // Cancel additional notifications for monthly overflow handling
        identifiersToRemove.append("\(identifier)-feb28")
        for month in [4, 6, 9, 11] {
            identifiersToRemove.append("\(identifier)-month\(month)")
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
    }


    // Test function to trigger immediate notification
    func sendTestNotification() {
        print("🔔 sendTestNotification called")
        print("🔔 isAuthorized: \(isAuthorized)")

        // First check and request permission if needed
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 Current authorization status: \(settings.authorizationStatus.rawValue)")

            DispatchQueue.main.async {
                if settings.authorizationStatus != .authorized {
                    print("🔔 Requesting permission...")
                    self.requestPermission()
                    return
                }

                print("🔔 Creating test notification...")
                let content = UNMutableNotificationContent()
                content.title = "Test Notification 📱"
                content.body = "Notifications are working! Your budget app is ready."
                content.sound = .default

                // Use immediate trigger (0.1 seconds)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: "test-notification-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("🔔 Error scheduling notification: \(error)")
                    } else {
                        print("🔔 Test notification scheduled successfully!")
                    }
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // This makes notifications show even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification will present in foreground!")

        // Notifications are now just reminders - they don't trigger expense logging
        // The app checks for missed recurring expenses whenever it opens (via ContentView.onAppear)
        // This ensures expenses are logged at their scheduled time, not when notification fires

        // Show notification even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification tapped!")

        // Notifications are now just reminders - they don't trigger expense logging
        // The app checks for missed recurring expenses whenever it opens (via ContentView.onAppear)
        // When user taps notification, the app will open and automatically process missed expenses

        completionHandler()
    }
}