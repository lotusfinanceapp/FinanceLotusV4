import SwiftUI

// MARK: - Main App - ROOT VIEW CONTROLLER
struct ContentView: View {
    @StateObject private var dataManager = BudgetDataManager() // Manages all app data
    @EnvironmentObject var themeManager: ThemeManager // Manages app themes
    @State private var showMainApp = false // Controls transition animation
    @State private var selectedTab = 0 // Track selected tab for custom indicator
    @State private var showingSettings = false // Controls settings sheet
    
    var body: some View {
        // === APP FLOW LOGIC WITH SMOOTH TRANSITIONS ===
        ZStack {
            // === BACKGROUND LAYER - PREVENTS WHITE SPACE GLITCHES ===
            Color.colBackground
                .ignoresSafeArea(.all) // Cover entire screen including safe areas
                .zIndex(-1) // Always behind content
            
            if dataManager.budget == nil {
                // Show budget setup screen if no budget exists
                SetBudgetView(dataManager: dataManager)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .zIndex(0)
            } else {
                // Show main app with tab navigation if budget exists
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
                    ProgressView(dataManager: dataManager)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Overview")
                        }
                        .tag(0)

                    // === ANALYTICS TAB ===
                    AnalyticsView(dataManager: dataManager)
                        .tabItem {
                            Image(systemName: "chart.pie.fill")
                            Text("Analytics")
                        }
                        .tag(1)

                    // === HISTORY TAB ===
                    HistoryView(dataManager: dataManager)
                        .tabItem {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History")
                        }
                        .tag(2)

                    // === LOG EXPENSE TAB ===
                    LogSpendingView(dataManager: dataManager)
                        .tabItem {
                            Image(systemName: "dollarsign.circle")
                            Text("Log Expense")
                        }
                        .tag(3)
                }
                .accentColor(.colAccent)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .zIndex(1)
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
        }
        .id(themeManager.themeUpdateTrigger) // Force view recreation on theme change
        .animation(.easeInOut(duration: 0.4), value: dataManager.budget != nil)
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .onChange(of: themeManager.currentTheme) { _ in
            // Update window background when theme changes
            updateWindowBackground()
            // Update tab bar when theme changes
            configureTabBar()
        }
        .onChange(of: themeManager.themeUpdateTrigger) { _ in
            // Force UI refresh when theme updates
            updateWindowBackground()
            configureTabBar()
        }
        .onAppear {
            // Set initial window background
            updateWindowBackground()
            // Configure tab bar with proper theme colors
            configureTabBar()
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
        let cardBackgroundColor: UIColor
        switch themeManager.currentTheme {
        case .lotus:
            cardBackgroundColor = UIColor(red: 0.94, green: 0.87, blue: 0.90, alpha: 1.0) // #F0DDE6
        case .original:
            cardBackgroundColor = UIColor(red: 0.41, green: 0.74, blue: 0.42, alpha: 1.0) // #68BC6C  
        case .ocean:
            cardBackgroundColor = UIColor(red: 0.88, green: 0.96, blue: 0.99, alpha: 1.0) // #E1F5FE
        case .sunset:
            cardBackgroundColor = UIColor(red: 1.0, green: 0.88, blue: 0.70, alpha: 1.0) // #FFE0B2
        case .midnight:
            cardBackgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // #1E1E1E
        case .lavender:
            cardBackgroundColor = UIColor(red: 0.95, green: 0.90, blue: 0.96, alpha: 1.0) // #F3E5F5
        case .mint:
            cardBackgroundColor = UIColor(red: 0.88, green: 0.97, blue: 0.98, alpha: 1.0) // #E0F7FA
        }
        
        appearance.backgroundColor = cardBackgroundColor
        
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
            .previewDisplayName("Main App")
    }
}
#endif
