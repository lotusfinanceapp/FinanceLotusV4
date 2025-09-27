import SwiftUI

// MARK: - Theme Manager - HANDLES APP COLOR THEMES
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .lotus
    @Published var themeUpdateTrigger = 0 // Force UI updates
    
    enum AppTheme: String, CaseIterable, Identifiable {
        case original = "Original Green"
        case lotus = "Lotus Pink & Green"
        case ocean = "Ocean Blue"
        case sunset = "Sunset Orange"
        case midnight = "Midnight Dark"
        case lavender = "Lavender Purple"
        case mint = "Fresh Mint"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            return self.rawValue
        }
        
        var description: String {
            switch self {
            case .original:
                return "Classic green finance theme"
            case .lotus:
                return "Soft pink and green lotus inspired"
            case .ocean:
                return "Clean blues and whites like ocean waves"
            case .sunset:
                return "Warm oranges and corals like sunset"
            case .midnight:
                return "Sleek dark theme with blue accents"
            case .lavender:
                return "Elegant purples and soft whites"
            case .mint:
                return "Fresh mint greens and crisp whites"
            }
        }
        
        var previewColors: [Color] {
            switch self {
            case .original:
                return [Color(hex: "#388E3C"), Color(hex: "#9CCC65"), Color(hex: "#FADADD")]
            case .lotus:
                return [Color(hex: "#7DB87D"), Color(hex: "#F2C2D4"), Color(hex: "#A8D5A8")]
            case .ocean:
                return [Color(hex: "#2196F3"), Color(hex: "#E3F2FD"), Color(hex: "#64B5F6")]
            case .sunset:
                return [Color(hex: "#FF7043"), Color(hex: "#FFF3E0"), Color(hex: "#FFAB91")]
            case .midnight:
                return [Color(hex: "#1A1A1A"), Color(hex: "#42A5F5"), Color(hex: "#2C2C2C")]
            case .lavender:
                return [Color(hex: "#9C27B0"), Color(hex: "#F3E5F5"), Color(hex: "#BA68C8")]
            case .mint:
                return [Color(hex: "#00BCD4"), Color(hex: "#E0F7FA"), Color(hex: "#4DD0E1")]
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
        currentTheme = theme
        saveTheme()
        // Apply theme colors to Color extension
        Color.applyTheme(theme)
        
        // Update window background immediately
        updateWindowBackground()
        
        // Force UI update by incrementing trigger
        themeUpdateTrigger += 1
        
        // Force UI update by posting notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
        }
    }
    
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
    }
}