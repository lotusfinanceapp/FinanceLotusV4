import SwiftUI

// MARK: - Theme Manager - HANDLES APP COLOR THEMES
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .lotus
    @Published var themeUpdateTrigger = 0 // Force UI updates
    
    enum AppTheme: String, CaseIterable, Identifiable {
        case lotus = "Light Mode"
        case midnight = "Midnight Dark"

        var id: String { self.rawValue }

        var displayName: String {
            return self.rawValue
        }

        var description: String {
            switch self {
            case .lotus:
                return "Light theme with soft colors"
            case .midnight:
                return "Dark theme with blue accents"
            }
        }

        var previewColors: [Color] {
            switch self {
            case .lotus:
                return [Color(hex: "#4A90E2"), Color(hex: "#F8F9FA"), Color(hex: "#6B7280")]
            case .midnight:
                return [Color(hex: "#1A1A1A"), Color(hex: "#42A5F5"), Color(hex: "#2C2C2C")]
            }
        }
    }
    
    init() {
        loadTheme()
        // Force immediate UI update
        themeUpdateTrigger += 1
        // Set initial window background
        DispatchQueue.main.async {
            self.updateWindowBackground()
            // Post notification for immediate theme application
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        // Only proceed if theme is different from current
        guard currentTheme != theme else { return }

        // Save theme immediately
        currentTheme = theme
        saveTheme()

        // Delay the actual theme application and restart to allow SettingsView to remain on screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Apply theme colors to Color extension
            Color.applyTheme(theme)

            // Update window background
            self.updateWindowBackground()

            // Configure TextField placeholder appearance
            self.configureTextFieldAppearance()

            // Force UI update by incrementing trigger
            self.themeUpdateTrigger += 1

            // Relaunch the app with smooth transition
            self.restartApp()
        }
    }

    // Function to restart the app with smooth transition
    private func restartApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {

            // Create new view controller
            let newRootView = ContentView()
                .environmentObject(ThemeManager.shared)
                .environmentObject(BudgetDataManager())
                .environmentObject(NotificationManager())
            let newViewController = UIHostingController(rootView: newRootView)

            // Animate the transition with fade
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = newViewController
                window.makeKeyAndVisible()
            })
        }
    }

    // Singleton instance for app-wide access
    static let shared = ThemeManager()
    
    // Update window background to match current theme
    private func updateWindowBackground() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    window.backgroundColor = UIColor(Color.colBackground)
                }
            }
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
            Color.applyTheme(theme)
        } else {
            // Apply default theme if no saved theme
            Color.applyTheme(currentTheme)
        }
        // Configure TextField placeholder appearance
        configureTextFieldAppearance()
    }

    // Configure TextField placeholder text color based on current theme
    private func configureTextFieldAppearance() {
        DispatchQueue.main.async {
            UITextField.appearance().attributedPlaceholder = NSAttributedString(
                string: "",
                attributes: [
                    .foregroundColor: UIColor(Color.colSecondaryText.opacity(0.6))
                ]
            )
        }
    }
}