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
    @StateObject private var themeManager = ThemeManager() // Global theme manager
    
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
                    }
                }
                .transition(.opacity)
            } else {
                ContentView() // Main app interface
                    .environmentObject(themeManager) // Inject theme manager
                    .transition(.opacity)
            }
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