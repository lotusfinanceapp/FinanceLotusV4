# Toolbar Style Guide

## Standard Toolbar Configuration

All full-screen views in the app should use this consistent toolbar style to match the clean, modern design with opaque background that doesn't turn grey when scrolling.

### ✅ Correct Implementation

```swift
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
        Text("View Title")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.colPrimaryText)
    }

    // Optional trailing button
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { /* action */ }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.colAccent)
        }
    }
}
.onAppear {
    // Configure navigation bar appearance
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(Color.colBackground)
    appearance.shadowColor = .clear
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}
```

### ❌ What NOT to Include

**Do NOT add these modifiers:**
```swift
.toolbarBackground(Color.colBackground, for: .navigationBar)  // ❌ Creates white line
.toolbarBackground(.visible, for: .navigationBar)             // ❌ Creates white line
.toolbarBackground(.hidden, for: .navigationBar)              // ❌ Makes toolbar transparent/see-through
```

### ⚠️ Important: Opaque Background

The `.onAppear` configuration is **required** to:
- Keep the toolbar background opaque and matching the theme
- Prevent the toolbar from turning grey when scrolling
- Remove the shadow line below the toolbar
- Ensure consistent appearance across all views

### 🔧 CRITICAL: Placement of .onAppear

The `.onAppear` modifier **MUST** be placed **OUTSIDE** the NavigationView closing brace.

**✅ Correct Placement (outside NavigationView):**
```swift
NavigationView {
    ScrollView {
        // ... content ...
    }
    .background(Color.colBackground.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        // toolbar items
    }
} // <-- NavigationView closes HERE
.sheet(...)
.fullScreenCover(...)
.onAppear {
    // ✅ CORRECT: Place navigation bar config HERE (outside NavigationView)
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(Color.colBackground)
    appearance.shadowColor = .clear
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}
```

**❌ Incorrect Placement (inside NavigationView - causes grey toolbar on scroll):**
```swift
NavigationView {
    ScrollView {
        // ... content ...
    }
    .background(Color.colBackground.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        // toolbar items
    }
    .onAppear {
        // ❌ WRONG: Causes toolbar to turn grey when scrolling
        let appearance = UINavigationBarAppearance()
        // ...
    }
} // <-- NavigationView closes here
```

**Why it matters:**
- `UINavigationBar.appearance()` is a **global** setting that affects ALL navigation bars
- When placed inside NavigationView's modifier chain, it conflicts with scroll behavior
- iOS applies a default material effect (grey background) when scrolling
- Placing `.onAppear` outside prevents this conflict

### 📏 Button Specifications

- **Size:** `.font(.system(size: 24))` for all toolbar buttons
- **Color:** `.foregroundColor(.colAccent)` for icons
- **Icons:** Use filled circle variants (`.fill` suffix)
  - Back button: `arrow.left.circle.fill`
  - Add button: `plus.circle.fill`
  - Edit button: `pencil.circle.fill`
  - Checkmark: `checkmark.circle.fill`

### 📝 Title Specifications

- **Font:** `.font(.headline)`
- **Weight:** `.fontWeight(.semibold)`
- **Color:** `.foregroundColor(.colPrimaryText)`
- **Placement:** `placement: .principal` (centered)

## Reference Views

These views implement the standard toolbar correctly:
- `SpendingGraphView.swift`
- `CompareView.swift`
- `RecurringExpensesManagementView.swift`
- `AllExpensesView.swift`
- `TransactionDetailView.swift`
- `RecurringTransactionDetailView.swift`
- `CategoryManagementView.swift`
- `CalendarView.swift`

## Why This Style?

This configuration ensures:
- ✅ No horizontal white separator line below toolbar
- ✅ Clean, transparent navigation bar
- ✅ Consistent with CircleExpansionView design
- ✅ Modern, minimal aesthetic
- ✅ Toolbar blends seamlessly with page content
