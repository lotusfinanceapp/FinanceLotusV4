# Budget Tracker App - Product Requirements Document

## 1. Overview

**App Name:** Budget Tracker (Finance Demo)

**Platform:** iOS (SwiftUI)

**Purpose:** A comprehensive personal finance management app that helps users track expenses, manage budgets, analyze spending patterns, and manage recurring expenses with smart notifications.

---

## 2. Core Features

### 2.1 Budget Management
- **Set Monthly Budget:** Users can set a monthly budget for the current month or adjust it anytime
- **Budget Persistence:** Budget data saved to UserDefaults and Codable structs
- **Budget Display:** Show budget amount, spent amount, and remaining amount
- **Budget Editing:** Full-screen modal to edit budget with validation

### 2.2 Expense Tracking
- **Log Expenses:** Quick expense logging with amount, category, subcategory, note, and date
- **Standard Categories:** Pre-built categories (Food, Transport, Shopping, Entertainment, Bills, Health, Other)
- **Custom Categories:** Users can create custom categories with custom icons and colors
- **Subcategories:** Each category can have multiple subcategories for detailed tracking
- **Expense Details:** View, edit, and delete individual expenses
- **Expense Validation:** Prevent logging $0 amounts or invalid data
- **Date Selection:** Full calendar picker for expense dates

### 2.3 Recurring Expenses
- **Recurrence Types:** Single Time, Daily, Weekly, Monthly, Yearly
- **Daily Recurring:** Set time of day for daily expenses
- **Weekly Recurring:** Select day of week and time (12:00 PM default)
- **Monthly Recurring:** Select day of month (handles edge cases like day 31, 30 with overflow to last day)
- **Yearly Recurring:** Set month and day (1st of selected month)
- **Recurring Management:** Full CRUD operations with dedicated management view
- **Recurring History:** View past and future occurrences of recurring expenses
- **Smart Date Handling:** February 28/29 handling, month overflow logic for days 29-31

### 2.4 Analytics & Insights
- **Overview Screen:** Dashboard with recent expenses, category breakdown, spending graph
- **Spending Graph:** Interactive line chart showing daily spending with tap-to-see-details popup
- **Category Analytics:** Pie chart breakdown of spending by category
- **Monthly Comparison:** Compare spending across selected months
- **Category Details:** View all expenses in a category with drill-down capability
- **Filter by Amount:** Min/max amount filtering for expenses
- **See All Expenses:** Sortable, searchable expense list with edit mode
- **Daily Averages:** Calculate and display average daily spending per category
- **Recent Expenses:** Alphabetically sorted by category when amounts are equal

### 2.5 Notifications System
- **Expense Confirmation:** Notification when expense is logged with amount and category
- **Recurring Notifications:** Smart notifications for recurring expenses at scheduled times
- **Permission Handling:** Request iOS notification permissions with graceful fallback
- **Toggle Control:** In-app toggle to enable/disable notifications (separate from iOS settings)
- **Settings Integration:** If notifications disabled in iOS, prompt users to enable with direct link to iOS Settings
- **Dynamic Currency:** Notifications show correct currency symbol based on user preference

### 2.6 Settings
- **Theme Management:** Light mode (Lotus) and Dark mode (Midnight)
  - Light theme: Clean whites with blue accents
  - Dark theme: Deep blacks with blue accents
- **Theme Persistence:** Save theme preference to UserDefaults
- **Smooth Theme Transitions:** App reloads with fade transition when theme changes
- **Notification Toggle:** Enable/disable notifications in app settings
- **Currency Selection:** Choose from USD, EUR, CNY, JPY, GBP, CAD
- **Currency Persistence:** Save preference to UserDefaults
- **Dynamic Currency Symbols:** All displays update based on selected currency
  - USD: $
  - EUR: €
  - GBP: £
  - CAD: $
  - JPY: ¥
  - CNY: ¥

### 2.7 Navigation & UI
- **Tab Navigation:** 4-tab bottom navigation
  1. Overview (house icon)
  2. Analytics (pie chart icon)
  3. History (clock icon)
  4. Log Expense (dollar sign icon)
- **Launch Screen:** Animated splash screen before main app
- **Logo Component:** Custom logo displayed in header
- **Settings Access:** Settings button in top-right corner of main view
- **Modals & Sheets:**
  - Full-screen covers for detailed views
  - Half-screen sheets for month picker
  - Alert dialogs for confirmations and notifications

---

## 3. Data Models

### 3.1 Core Models

#### Budget
```
- id: UUID
- amount: Double
- period: BudgetPeriod (enum: monthly, weekly, daily)
- createdDate: Date
- updatedDate: Date
```

#### Expense
```
- id: UUID
- amount: Double
- category: CustomCategory (or raw string for standard)
- subcategory: String?
- note: String
- date: Date
- recurringExpenseId: UUID? (if part of recurring series)
- createdDate: Date
- updatedDate: Date
```

#### RecurringExpense
```
- id: UUID
- amount: Double
- category: CustomCategory
- subcategory: String?
- note: String
- recurrenceType: RecurrenceType (enum: singleTime, daily, weekly, monthly, yearly)
- selectedDate: Date? (for singleTime)
- selectedTime: Date? (for daily)
- selectedDayOfWeek: Int? (for weekly, 1-7 where 1=Sunday)
- selectedDayOfMonth: Int? (for monthly, 1-31)
- selectedMonthOfYear: Int? (for yearly, 1-12)
- createdDate: Date
- updatedDate: Date
```

#### CustomCategory
```
- id: UUID
- name: String
- icon: String (SF Symbols icon name)
- color: Color
- subcategories: [String]
- createdDate: Date
```

#### StandardCategory (Enum)
```
- food (icon: fork.knife, color: red)
- transport (icon: car.fill, color: teal)
- shopping (icon: bag.fill, color: blue)
- entertainment (icon: film, color: green)
- bills (icon: receipt, color: yellow)
- health (icon: heart.fill, color: pink)
- other (icon: ellipsis, color: gray)
```

---

## 4. State Management

### 4.1 Data Manager
- **BudgetDataManager:** ObservableObject managing all app data
  - Loads/saves from persistent storage
  - Manages budget, expenses, recurring expenses, categories
  - Processes recurring expenses when app opens
  - Coordinates with NotificationManager for scheduling

### 4.2 Theme Manager
- **ThemeManager:** ObservableObject for theme state
  - Current theme property (@Published)
  - Theme switching with app reload
  - Color application system
  - Persistence via UserDefaults

### 4.3 Notification Manager
- **NotificationManager:** Manages all notification scheduling
  - iOS permission handling
  - In-app notification toggle checking
  - Schedule methods for different expense types
  - Cancellation methods for recurring expenses
  - Delegate implementation for foreground/tap handling

### 4.4 Category Manager
- **CategoryManager:** Manages custom categories
  - Add/edit/delete categories
  - Manage subcategories
  - Color and icon selection

---

## 5. Persistence Strategy

### 5.1 File Storage
- **Documents Directory:** Store JSON files for:
  - budget.json (current budget)
  - expenses.json (all expenses)
  - recurringExpenses.json (all recurring expense definitions)
  - categories.json (custom categories)

### 5.2 UserDefaults
- `selectedTheme` - Current theme preference
- `selectedCurrency` - Selected currency code
- `notificationsEnabled` - In-app notification toggle

### 5.3 Codable Protocol
- All models conform to Codable for JSON serialization
- Custom encoding/decoding for complex types (Color, UUID)

---

## 6. Screens & Views

### 6.1 Navigation Structure
```
AppCoordinator (Root)
├── LaunchScreen (Splash)
└── ContentView (Tab Navigation)
    ├── ProgressView (Overview Tab)
    │   ├── SpendingGraphView (Popup on chart tap)
    │   ├── CircleExpansionView (Expanded category view)
    │   └── CategoryDetailView (Full category details)
    │       ├── TransactionDetailView (Single transaction)
    │       └── RecurringTransactionDetailView (Single recurring expense)
    │
    ├── AnalyticsView (Analytics Tab)
    │   ├── AllExpensesView (See all with edit mode)
    │   │   └── TransactionDetailView
    │   ├── CompareView (Month comparison)
    │   └── AmountFilterView (Filter controls)
    │
    ├── HistoryView (History Tab)
    │   └── CalendarView (Calendar with recurring highlights)
    │
    ├── LogSpendingView (Log Expense Tab)
    │   ├── CustomNumberPad (Amount input)
    │   └── AddSubcategorySheet (New subcategory)
    │
    └── SettingsView (Full-screen modal)
        ├── SetBudgetView (Budget editor)
        └── OnboardingView (Tutorial, shown via test button)
            └── (Multiple onboarding screens, expandable)
```

### 6.2 Key Screens

#### Overview Tab (ProgressView)
- Monthly budget progress bar
- Recent expenses list
- Spending graph
- Category breakdown
- Tappable elements link to detailed views

#### Analytics Tab
- Default: All expenses sorted by date
- Compare View: Month-to-month comparison
- Filter options: Category, amount range, date range
- Edit mode: Shake animation, delete functionality

#### History Tab (CalendarView)
- Calendar grid showing expenses per day
- Recurring expense indicators
- Tap day to see expenses
- Month navigation

#### Log Expense Tab
- Category selection (grid or list)
- Subcategory selection (scrollable pills)
- Amount input with custom number pad
- Note field (text input)
- Date picker
- Submit button (saves expense + schedules notification)

#### Settings
- Budget management button
- Notification toggle with iOS settings link
- Theme selector (Lotus/Midnight)
- Currency selector
- Test onboarding button

---

## 7. UI/UX Design System

### 7.1 Color Palette

#### Light Mode (Lotus)
- Background: #F8F9FA
- Card Background: #FFFFFF
- Primary Text: #1F2937
- Secondary Text: #6B7280
- Accent: #4A90E2
- Success: #10B981
- Error: #EF4444

#### Dark Mode (Midnight)
- Background: #121212
- Card Background: #1E1E1E
- Primary Text: #FFFFFF
- Secondary Text: #B3B3B3
- Accent: #42A5F5
- Success: #42A5F5
- Error: #FF5722

### 7.2 Typography
- Headline: System font, bold, 28pt
- Title: System font, semibold, 20pt
- Body: System font, regular, 16pt
- Caption: System font, regular, 12pt
- Callout: System font, semibold, 16pt

### 7.3 Components
- Rounded rectangles (cornerRadius: 16) for cards
- Circle icons with colored backgrounds
- Custom tab bar (rounded, shadowed)
- Smooth animations (.easeInOut, .easeOut)
- Opacity + offset animations for staggered appearance
- Dividers with theme-aware colors

### 7.4 Interactive Elements
- Pull-to-refresh on expense lists
- Swipe gestures on expense rows
- Shake animation in edit mode
- Tap-to-expand cards
- Long-press for context menus (where applicable)

---

## 8. Business Logic

### 8.1 Expense Processing
1. User logs expense with category, amount, note, date
2. App saves to expenses.json
3. If it's a new category, save to categories.json
4. Schedule notification with dynamic currency symbol
5. Update budget remaining amount
6. Refresh UI with latest data

### 8.2 Recurring Expense Processing
1. User creates recurring expense with:
   - Amount, category, note
   - Recurrence type (daily/weekly/monthly/yearly)
   - Time/date parameters based on recurrence type
2. App saves to recurringExpenses.json
3. Scheduler creates multiple notification requests:
   - For monthly/day 30+, create overflow notifications for shorter months
   - For yearly, use 1st of selected month
4. When app opens, check for missed recurring expenses:
   - If scheduled time has passed, create expense entry
   - Log expense to expenses.json
   - Update budget
5. Notification fires at scheduled time (visual reminder only)

### 8.3 Budget Tracking
1. Set monthly budget for current month
2. App tracks total spent amount
3. Calculate remaining = budget - spent
4. Show visual progress (progress bar)
5. Alert if spending exceeds budget
6. Can edit budget anytime (updates all calculations)

### 8.4 Analytics Calculations
- Total spending: Sum of all expenses for period
- By category: Group expenses by category, sum amounts
- Daily average: Total / days in month
- Month-to-month: Compare totals across selected months
- Category trends: Show spending over time

---

## 9. Notifications

### 9.1 Local Notifications
- Scheduled using UserNotifications framework
- UNUserNotificationCenter for requesting permissions
- Foreground handling: Show banners even when app is open
- Tap handling: App opens and processes missed recurring expenses

### 9.2 Notification Content
- Title: "Expense Added ✅"
- Body: "[Currency Symbol][Amount] added to [Category]"
- Example: "€50.00 added to Groceries"

### 9.3 Permission Flow
1. App requests permission on first launch
2. User can enable/disable in iOS Settings
3. User can enable/disable in App Settings
4. If trying to enable in app but disabled in iOS:
   - Show alert with link to iOS Settings
   - Revert toggle
   - Close SettingsView
   - Open iOS Settings
   - On return, auto-check iOS status

---

## 10. Error Handling

### 10.1 Input Validation
- Prevent $0 or negative amounts
- Require category selection
- Require date within reasonable range
- Validate budget amount > $0

### 10.2 Data Validation
- Check for corrupted JSON files
- Fallback to default values if load fails
- Handle missing categories gracefully
- Validate recurring expense parameters

### 10.3 User Feedback
- Alert dialogs for validation errors
- Toast notifications for success (via notifications)
- Loading states for async operations
- Error messages in plain language

---

## 11. Performance Considerations

### 11.1 Optimization
- Lazy loading of expense lists
- Pagination for "See All" views (if large dataset)
- Memoization of calculated values (budgets, averages)
- Debounce text input in search/filter
- Background processing of recurring expenses

### 11.2 Memory Management
- Limit in-memory expense array to current month + 3 months
- Archive old data to separate files
- Use weak references in closures to prevent cycles

---

## 12. Testing Recommendations

### 12.1 Unit Tests
- Budget calculations
- Expense filtering and grouping
- Recurring expense date calculations
- Currency formatting
- Category management

### 12.2 UI Tests
- Expense logging flow
- Budget editing
- Category selection
- Theme switching
- Notification permissions flow

### 12.3 Integration Tests
- Full expense creation to display flow
- Recurring expense creation and notification scheduling
- Data persistence and reload
- Theme/currency changes across app

---

## 13. Future Enhancements

### Phase 2
- Export to CSV/PDF
- Budget sharing between users
- Investment tracking
- Income tracking (separate from expenses)
- Savings goals

### Phase 3
- Cloud sync (iCloud or custom backend)
- Multi-currency support with conversion rates
- AI-powered spending insights
- Receipt scanning via OCR
- Integration with banking APIs

### Phase 4
- Web dashboard
- Mobile app for Android
- Social features (compare with friends)
- Bill splitting
- Subscription tracking

---

## 14. Accessibility

### 14.1 Requirements
- VoiceOver support for all interactive elements
- Sufficient color contrast (WCAG AA)
- Dynamic type support for font sizing
- Haptic feedback for confirmations
- Alternative text for icons

---

## 15. Security & Privacy

### 15.1 Data Protection
- All data stored locally on device
- No cloud transmission (Phase 1)
- Encrypted Documents directory
- No analytics or tracking
- No personal data collection

### 15.2 Permissions
- Only request necessary permissions (Notifications)
- Display purpose strings clearly
- Allow permission revocation anytime

---

## 16. Onboarding

### 16.1 First Launch Experience
- **Screen 1:** Welcome splash with app mission
- **Screen 2:** Budget setup (required to use app)
- **Screen 3:** Feature overview (categories, recurring expenses)
- **Screen 4:** Notification permissions request
- **Screen 5:** Currency selection
- **Screen 6:** Ready to go (link to main app)

### 16.2 In-App Tutorial
- Accessible via Settings → Test Onboarding
- Can be viewed anytime
- Provides feature overview and tips
- Screen by screen progression

---

## 17. File Structure (Code Organization)

```
FinanceDemo/
├── App/
│   └── FinancedemoApp.swift
├── Views/
│   ├── Core/
│   │   ├── ContentView.swift
│   │   └── SettingsView.swift
│   ├── Budget/
│   │   ├── SetBudgetView.swift
│   │   ├── BudgetEditView.swift
│   │   └── BudgetInputCard.swift
│   ├── Analytics/
│   │   ├── ProgressView.swift
│   │   ├── AnalyticsView.swift
│   │   ├── AllExpensesView.swift
│   │   ├── CompareView.swift
│   │   ├── SpendingGraphView.swift
│   │   ├── CalendarView.swift
│   │   ├── CategoryDetailView.swift
│   │   ├── TransactionDetailView.swift
│   │   └── Components/
│   │       ├── ExpenseRowView.swift
│   │       ├── AmountFilterView.swift
│   │       └── CategoryPickerView.swift
│   ├── Categories/
│   │   ├── CategoryManagementView.swift
│   │   ├── CategoryEditView.swift
│   │   ├── CircleExpansionView.swift
│   │   └── RecurringDetailView.swift
│   ├── Expenses/
│   │   ├── LogSpendingView.swift
│   │   ├── HistoryView.swift
│   │   ├── ExpenseDetailView.swift
│   │   ├── AddRecurringExpenseView.swift
│   │   ├── AddSubcategorySheet.swift
│   │   ├── RecurringExpensesManagementView.swift
│   │   └── RecurringTransactionDetailView.swift
│   ├── Components/
│   │   ├── CustomNumberPad.swift
│   │   ├── LogoComponent.swift
│   │   └── StatCard.swift
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   └── LaunchScreen.swift
├── ViewModels/
│   └── BudgetDataManager.swift
├── Models/
│   ├── Budget.swift
│   ├── Expense.swift
│   ├── RecurringExpense.swift
│   ├── CategoryManager.swift
│   └── StandardCategories.swift
├── Managers/
│   ├── ThemeManager.swift
│   ├── NotificationManager.swift
│   └── StorageManager.swift
├── Extensions/
│   ├── Color+Extensions.swift
│   └── DateFormatter+Extensions.swift
└── Resources/
    └── Assets.xcassets
```

---

## 18. Version & Release Notes

### v1.0.0 (Current)
- Core expense tracking with standard and custom categories
- Budget management and progress tracking
- Recurring expenses with smart scheduling
- Analytics and spending insights
- Dark/Light theme support
- Multi-currency support
- Local notifications
- Category and amount filtering
- Edit/Delete expenses with confirmation
- Custom number pad for amount input

---

## 19. Success Metrics

- Users successfully log expenses on first day
- Budget setup completion rate > 80%
- Daily active user retention > 60% (Day 1 to Day 7)
- Average expenses tracked per user > 20/month
- Theme/currency customization adoption > 40%
- Notification engagement rate > 50% (if enabled)

---

## 20. Technical Stack

### Technologies
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Storage:** File system (Documents directory) + UserDefaults
- **Notifications:** UserNotifications framework
- **Persistence:** Codable protocol (JSON)
- **Architecture:** MVVM with ObservableObject
- **Minimum iOS Version:** iOS 15+

---

This PRD provides a complete blueprint for recreating the Budget Tracker app. All features, data models, screens, and business logic are documented for full implementation.
