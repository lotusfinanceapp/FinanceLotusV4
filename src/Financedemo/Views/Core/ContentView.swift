import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let switchToLogExpenseTab = Notification.Name("switchToLogExpenseTab")
}

// MARK: - Main App - ROOT VIEW CONTROLLER
struct ContentView: View {
    @StateObject private var dataManager = BudgetDataManager() // Manages all app data
    @EnvironmentObject var themeManager: ThemeManager // Manages app themes
    @EnvironmentObject var notificationManager: NotificationManager // Manages notifications
    @State private var showMainApp = false // Controls transition animation
    @State private var selectedTab = 0 // Track selected tab for custom indicator
    @State private var previousTab = 0 // Track previous tab
    @State private var showingSettings = false // Controls settings sheet
    @State private var showingCustomNumberPad = false // Controls custom number pad
    @State private var expenseAmount = "" // Amount for number pad
    @State private var selectedCategory: CustomCategory? = nil // Track selected category
    @State private var initialSubcategoryName: String? = nil // Track initial subcategory for preselection
    @State private var showingUnsavedExpenseAlert = false // Alert for unsaved expense
    @State private var pendingTabSelection: Int? = nil // Store pending tab change
    
    var body: some View {
        // === APP FLOW LOGIC WITH SMOOTH TRANSITIONS ===
        ZStack {
            // === BACKGROUND LAYER - PREVENTS WHITE SPACE GLITCHES ===
            Color.colBackground
                .ignoresSafeArea(.all) // Cover entire screen including safe areas
                .zIndex(-1) // Always behind content
            
            // Show main app with tab navigation
            // Note: Budget is guaranteed to exist after onboarding completion
            TabView(selection: $selectedTab) {
                // === OVERVIEW TAB ===
                // Icon options - choose one:
                // "house.fill" - Home icon
                // "squares.below.rectangle" - Dashboard icon
                // "gauge" - Speedometer icon
                // "chart.xyaxis.line" - Line chart icon
                // "circle.grid.3x3.fill" - Grid icon
                // "target" - Target icon
                // "scope" - Scope icon
                // "chart.bar.fill" - Original bar chart
                ProgressView(dataManager: dataManager, isActiveTab: selectedTab == 0, selectedTab: $selectedTab)
                    .tabItem {
                        if UIScreen.main.bounds.height < 670 {
                            Image(systemName: "house.fill")
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 14))
                                Text("Overview")
                                    .lineLimit(1)
                                    .font(.system(size: 11))
                            }
                        }
                    }
                    .tag(0)

                // === ANALYTICS TAB ===
                AnalyticsView(dataManager: dataManager)
                    .tabItem {
                        if UIScreen.main.bounds.height < 670 {
                            Image(systemName: "chart.pie.fill")
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 14))
                                Text("Analytics")
                                    .lineLimit(1)
                                    .font(.system(size: 11))
                            }
                        }
                    }
                    .tag(1)

                // === HISTORY TAB ===
                HistoryView(dataManager: dataManager)
                    .tabItem {
                        if UIScreen.main.bounds.height < 670 {
                            Image(systemName: "clock.arrow.circlepath")
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                Text("History")
                                    .lineLimit(1)
                                    .font(.system(size: 11))
                            }
                        }
                    }
                    .tag(2)

                // === LOG EXPENSE TAB ===
                LogSpendingView(
                    dataManager: dataManager,
                    showingCustomNumberPad: $showingCustomNumberPad,
                    expenseAmount: $expenseAmount,
                    selectedCategory: $selectedCategory,
                    initialSubcategoryName: initialSubcategoryName
                )
                    .tabItem {
                        if UIScreen.main.bounds.height < 670 {
                            Image(systemName: "dollarsign.circle.fill")
                        } else {
                            VStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 14))
                                Text("Log Expense")
                                    .lineLimit(1)
                                    .font(.system(size: 11))
                            }
                        }
                    }
                    .tag(3)
            }
            .accentColor(.colAccent)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .zIndex(1)
            .onChange(of: selectedTab) { newValue in
                // Skip if this is from reverting back
                if let pending = pendingTabSelection, newValue == 3 {
                    return
                }

                // Check if leaving Log Expense tab with unsaved data
                if previousTab == 3 && newValue != 3 {
                    // Check if there's unsaved expense data (both amount AND category)
                    let hasAmount = !expenseAmount.isEmpty && (Double(expenseAmount) ?? 0) > 0
                    let hasCategory = selectedCategory != nil

                    if hasAmount && hasCategory {
                        // Store the pending tab selection
                        pendingTabSelection = newValue
                        // Revert to current tab (without triggering onChange loop)
                        selectedTab = 3
                        // Show alert
                        showingUnsavedExpenseAlert = true
                        return
                    } else {
                        // Clear any partial data after a delay when leaving without alert
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expenseAmount = ""
                            selectedCategory = nil
                            initialSubcategoryName = nil
                        }
                    }
                }

                // Update previous tab
                previousTab = newValue

                // Process recurring expenses when switching tabs
                dataManager.processRecurringExpenses()
            }
            
            // === FIXED LOGO HEADER WITH STATIC BACKGROUND ===
            VStack {
                HStack {
                    LogoComponent(size: 50, opacity: 1.0)
                        .scaleEffect(1.0)
                        .animation(.easeOut(duration: 0.6), value: true)

                    Spacer()

                    // === SETTINGS ICON ===
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.colAccent)
                            .scaleEffect(1.0)
                            .animation(.easeOut(duration: 0.6), value: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(
                    Color.colBackground
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        .ignoresSafeArea(.all, edges: .top)
                )

                Spacer()
            }
            .zIndex(10) // Always on top

            // === CUSTOM NUMBER PAD OVERLAY ===
            if showingCustomNumberPad {
                CustomNumberPad(
                    text: $expenseAmount,
                    isPresented: $showingCustomNumberPad,
                    onDismiss: {
                        showingCustomNumberPad = false
                    }
                )
                .zIndex(1000)
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
                .environmentObject(dataManager)
                .environmentObject(themeManager)
                .environmentObject(notificationManager)
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedExpenseAlert) {
            Button("Stay", role: .cancel) {
                // Stay on current tab, do nothing
                pendingTabSelection = nil
            }
            Button("Exit", role: .destructive) {
                // Switch tabs first
                if let pending = pendingTabSelection {
                    // Update previous tab first to prevent loop
                    previousTab = pending
                    selectedTab = pending
                    pendingTabSelection = nil
                }

                // Clear data after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    expenseAmount = ""
                    selectedCategory = nil
                    initialSubcategoryName = nil
                }
            }
        } message: {
            Text("You're about to leave without saving this expense.")
        }
        .onChange(of: themeManager.currentTheme) { _ in
            DispatchQueue.main.async {
                // Update window background when theme changes
                updateWindowBackground()
                // Update tab bar when theme changes
                configureTabBar()
            }
        }
        .onAppear {
            // Set initial window background
            updateWindowBackground()
            // Configure tab bar with proper theme colors
            configureTabBar()

            // Link notification manager to data manager
            dataManager.setNotificationManager(notificationManager)

            // Process any pending recurring expenses
            dataManager.processRecurringExpenses()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Process recurring expenses when app comes to foreground
            dataManager.processRecurringExpenses()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToLogExpenseTab)) { notification in
            // Switch to log expense tab and set category/subcategory
            selectedTab = 3

            if let userInfo = notification.userInfo,
               let category = userInfo["category"] as? CustomCategory {
                selectedCategory = category

                // Set subcategory if provided
                if let subcategoryName = userInfo["subcategory"] as? String {
                    initialSubcategoryName = subcategoryName
                } else {
                    initialSubcategoryName = nil
                }
            }
        }
    }
    
    // === WINDOW BACKGROUND UPDATE FUNCTION ===
    private func updateWindowBackground() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.backgroundColor = UIColor(Color.colBackground)
            }
        }
    }
    
    // === TAB BAR CONFIGURATION FUNCTION ===
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set background color based on current theme
        appearance.backgroundColor = UIColor(Color.colCardBackground)
        
        // Make tab bar fully rounded (all corners)
        UITabBar.appearance().layer.cornerRadius = 30
        UITabBar.appearance().layer.masksToBounds = false
        UITabBar.appearance().layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        // Enhanced modern shadow
        UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
        UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -4)
        UITabBar.appearance().layer.shadowRadius = 12
        UITabBar.appearance().layer.shadowOpacity = 0.15
        
        // Add subtle border for modern look
        UITabBar.appearance().layer.borderWidth = 0.5
        UITabBar.appearance().layer.borderColor = UIColor(Color.colAccent.opacity(0.2)).cgColor
        
        // Better icon and text positioning - slightly lower and closer together
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 4)
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 4)
        
        // Set unselected icon colors to be more subtle
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.colSecondaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.colSecondaryText)]
        
        // Set selected icon colors to accent color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.colAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.colAccent)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
}

// MARK: - Preview
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ThemeManager())
            .environmentObject(NotificationManager())
            .previewDisplayName("Main App")
    }
}
#endif
