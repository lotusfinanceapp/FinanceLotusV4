import SwiftUI

// MARK: - App Entry Point - MAIN APP LAUNCHER
@main
struct BudgetTrackApp: App {
    var body: some Scene {
        WindowGroup {
            AppCoordinator() // Handles launch screen and main app transition
        }
    }
}

// MARK: - App Coordinator - MANAGES LAUNCH TO MAIN APP TRANSITION
struct AppCoordinator: View {
    @State private var showLaunchScreen = true
    @State private var showOnboarding = false
    @State private var onboardingInitialized = false
    @StateObject private var themeManager = ThemeManager() // Global theme manager
    @StateObject private var notificationManager = NotificationManager() // Global notification manager
    @StateObject private var dataManager = BudgetDataManager() // Data manager for budget

    init() {
        // Set initial tab bar appearance before any views are created
        configureInitialTabBarAppearance()
    }

    var body: some View {
        ZStack {
            // Always maintain background color to prevent white flashes
            Color.colBackground
                .ignoresSafeArea(.all)

            if showLaunchScreen {
                LaunchScreen {
                    // Called when launch animation completes
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLaunchScreen = false
                        // Check onboarding requirement after launch screen
                        if !onboardingInitialized {
                            checkOnboardingRequirement()
                            onboardingInitialized = true
                        }
                    }
                }
                .transition(.opacity)
            } else if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .environmentObject(dataManager)
                    .environmentObject(notificationManager)
                    .transition(.opacity)
            } else {
                ContentView() // Main app interface
                    .environmentObject(themeManager) // Inject theme manager
                    .environmentObject(notificationManager) // Inject notification manager
                    .environmentObject(dataManager) // Inject data manager
                    .transition(.opacity)
                    .onAppear {
                        notificationManager.requestPermission()
                    }
            }
        }
    }

    private func checkOnboardingRequirement() {
        // Show onboarding if:
        // 1. User hasn't completed onboarding, OR
        // 2. User has completed onboarding but doesn't have a budget (shouldn't happen, but defensive)
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let hasBudget = dataManager.budget != nil

        // Only skip onboarding if BOTH conditions are true
        if hasCompletedOnboarding && hasBudget {
            showOnboarding = false
        } else {
            showOnboarding = true
        }
    }
    
    private func configureInitialTabBarAppearance() {
        // Set default tab bar appearance with lotus theme color (never white)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.94, green: 0.87, blue: 0.90, alpha: 1.0) // #F0DDE6 (lotus theme)
        
        // Set appearance globally to prevent white flash
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}