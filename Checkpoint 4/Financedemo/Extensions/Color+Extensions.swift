import SwiftUI

// MARK: - App Color Palette - DYNAMIC THEME SYSTEM
extension Color {
    // === DYNAMIC COLOR PROPERTIES ===
    private static var _colBackground = Color(hex: "#F9F4F6")
    private static var _colGradient1 = Color(hex: "#F2C2D4")
    private static var _colGradient2 = Color(hex: "#A8D5A8")
    private static var _colButton = Color(hex: "#7DB87D")
    private static var _colIconPrimary = Color(hex: "#7DB87D")
    private static var _colIconSecondary = Color(hex: "#F2C2D4")
    private static var _colExpenseBackground = Color(hex: "#F5E6ED")
    private static var _colExpenseText = Color(hex: "#C66B85")
    private static var _colProgressTrack = Color(hex: "#E8F5E8")
    private static var _colProgressFill1 = Color(hex: "#F2C2D4")
    private static var _colProgressFill2 = Color(hex: "#7DB87D")
    private static var _colStatBudget = Color(hex: "#7DB87D")
    private static var _colStatSpent = Color(hex: "#D498A7")
    private static var _colStatRemaining = Color(hex: "#7DB87D")
    private static var _colAlertText = Color(hex: "#C66B85")
    private static var _colAlertBackground = Color(hex: "#F5E6ED")
    private static var _colCardBackground = Color(hex: "#F0DDE6")
    private static var _colInputBackground = Color(hex: "#F5E6ED")
    private static var _colAccent = Color(hex: "#7DB87D")
    private static var _colButtonText = Color(hex: "#FFFFFF")
    private static var _colRemainingText = Color(hex: "#7DB87D")
    private static var _colBackButtonIcon = Color(hex: "#7DB87D")
    private static var _colCalendarIcon = Color(hex: "#D498A7")
    private static var _colChartIcon = Color(hex: "#7DB87D")
    private static var _colDollarIcon = Color(hex: "#F4A460")
    private static var _colTargetIcon = Color(hex: "#7DB87D")
    private static var _colPieChartIcon = Color(hex: "#D498A7")
    private static var _colPrimaryText = Color.primary
    private static var _colSecondaryText = Color.secondary
    private static var _colOnAccent = Color.white // Text color on accent colored backgrounds
    private static var _colPercentageText = Color.primary
    private static var _colEmptyStateText = Color.secondary
    private static var _colInputText = Color.primary // Text color inside input fields

    // === PUBLIC ACCESSORS ===
    static var colBackground: Color { _colBackground }
    static var colGradient1: Color { _colGradient1 }
    static var colGradient2: Color { _colGradient2 }
    static var colButton: Color { _colButton }
    static var colIconPrimary: Color { _colIconPrimary }
    static var colIconSecondary: Color { _colIconSecondary }
    static var colExpenseBackground: Color { _colExpenseBackground }
    static var colExpenseText: Color { _colExpenseText }
    static var colProgressTrack: Color { _colProgressTrack }
    static var colProgressFill1: Color { _colProgressFill1 }
    static var colProgressFill2: Color { _colProgressFill2 }
    static var colStatBudget: Color { _colStatBudget }
    static var colStatSpent: Color { _colStatSpent }
    static var colStatRemaining: Color { _colStatRemaining }
    static var colAlertText: Color { _colAlertText }
    static var colAlertBackground: Color { _colAlertBackground }
    static var colCardBackground: Color { _colCardBackground }
    static var colInputBackground: Color { _colInputBackground }
    static var colAccent: Color { _colAccent }
    static var colButtonText: Color { _colButtonText }
    static var colRemainingText: Color { _colRemainingText }
    static var colBackButtonIcon: Color { _colBackButtonIcon }
    static var colCalendarIcon: Color { _colCalendarIcon }
    static var colChartIcon: Color { _colChartIcon }
    static var colDollarIcon: Color { _colDollarIcon }
    static var colTargetIcon: Color { _colTargetIcon }
    static var colPieChartIcon: Color { _colPieChartIcon }
    static var colPrimaryText: Color { _colPrimaryText }
    static var colSecondaryText: Color { _colSecondaryText }
    static var colOnAccent: Color { _colOnAccent }
    static var colPercentageText: Color { _colPercentageText }
    static var colEmptyStateText: Color { _colEmptyStateText }
    static var colInputText: Color { _colInputText }
    
    // === THEME APPLICATION FUNCTION ===
    static func applyTheme(_ theme: ThemeManager.AppTheme) {
        print("DEBUG: Applying theme: \(theme.rawValue)")
        switch theme {
        case .lotus:
            // Light theme - Modern clean with blue accents
            _colBackground = Color(hex: "#F8F9FA")
            _colGradient1 = Color(hex: "#E8EFF5")
            _colGradient2 = Color(hex: "#4A90E2")
            _colButton = Color(hex: "#4A90E2")
            _colIconPrimary = Color(hex: "#4A90E2")
            _colIconSecondary = Color(hex: "#6B7280")
            _colExpenseBackground = Color(hex: "#EEF2F6")
            _colExpenseText = Color(hex: "#3B82F6")
            _colProgressTrack = Color(hex: "#E5E7EB")
            _colProgressFill1 = Color(hex: "#60A5FA")
            _colProgressFill2 = Color(hex: "#4A90E2")
            _colStatBudget = Color(hex: "#4A90E2")
            _colStatSpent = Color(hex: "#6B7280")
            _colStatRemaining = Color(hex: "#10B981")
            _colAlertText = Color(hex: "#EF4444")
            _colAlertBackground = Color(hex: "#FEF2F2")
            _colCardBackground = Color(hex: "#FFFFFF")
            _colInputBackground = Color(hex: "#F3F4F6")
            _colAccent = Color(hex: "#4A90E2")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#10B981")
            _colBackButtonIcon = Color(hex: "#4A90E2")
            _colCalendarIcon = Color(hex: "#6B7280")
            _colChartIcon = Color(hex: "#4A90E2")
            _colDollarIcon = Color(hex: "#F59E0B")
            _colTargetIcon = Color(hex: "#4A90E2")
            _colPieChartIcon = Color(hex: "#8B5CF6")
            _colPrimaryText = Color(hex: "#1F2937")
            _colSecondaryText = Color(hex: "#6B7280")
            _colOnAccent = Color.white
            _colPercentageText = Color(hex: "#1F2937")
            _colEmptyStateText = Color(hex: "#9CA3AF")
            _colInputText = Color(hex: "#1F2937")
            
        case .midnight:
            // Dark theme - Midnight dark with blue accents
            _colBackground = Color(hex: "#121212")
            _colGradient1 = Color(hex: "#2C2C2C")
            _colGradient2 = Color(hex: "#42A5F5")
            _colButton = Color(hex: "#1E88E5")
            _colIconPrimary = Color(hex: "#42A5F5")
            _colIconSecondary = Color(hex: "#424242")
            _colExpenseBackground = Color(hex: "#1E1E1E")
            _colExpenseText = Color(hex: "#42A5F5")
            _colProgressTrack = Color(hex: "#2C2C2C")
            _colProgressFill1 = Color(hex: "#42A5F5")
            _colProgressFill2 = Color(hex: "#1E88E5")
            _colStatBudget = Color(hex: "#42A5F5")
            _colStatSpent = Color(hex: "#64B5F6")
            _colStatRemaining = Color(hex: "#42A5F5")
            _colAlertText = Color(hex: "#FF5722")
            _colAlertBackground = Color(hex: "#1E1E1E")
            _colCardBackground = Color(hex: "#1E1E1E")
            _colInputBackground = Color(hex: "#2C2C2C")
            _colAccent = Color(hex: "#42A5F5")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#42A5F5")
            _colBackButtonIcon = Color(hex: "#42A5F5")
            _colCalendarIcon = Color(hex: "#64B5F6")
            _colChartIcon = Color(hex: "#42A5F5")
            _colDollarIcon = Color(hex: "#FFC107")
            _colTargetIcon = Color(hex: "#42A5F5")
            _colPieChartIcon = Color(hex: "#64B5F6")
            _colPrimaryText = Color.white
            _colSecondaryText = Color(hex: "#B3B3B3")
            _colOnAccent = Color.white
            _colPercentageText = Color.white
            _colEmptyStateText = Color(hex: "#B3B3B3")
            _colInputText = Color.white
        }
        print("DEBUG: Theme application completed for \(theme.rawValue)")
    }
    
    // === INDIVIDUAL CATEGORY COLORS - EDIT THESE TO CHANGE CATEGORY COLORS ===
    static let colCategoryFood = Color(hex: "#FF6B6B")          // Food & Dining category color (red)
    static let colCategoryTransport = Color(hex: "#4ECDC4")     // Transportation category color (teal)
    static let colCategoryShopping = Color(hex: "#45B7D1")      // Shopping category color (blue)
    static let colCategoryEntertainment = Color(hex: "#96CEB4") // Entertainment category color (green)
    static let colCategoryBills = Color(hex: "#FECA57")         // Bills & Utilities category color (yellow)
    static let colCategoryHealth = Color(hex: "#FF9FF3")        // Health & Fitness category color (pink)
    static let colCategoryOther = Color(hex: "#95A5A6")         // Other category color (gray)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - DateFormatter Extensions for Graph Navigation
extension DateFormatter {
    static let weekRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

// MARK: - Currency Helper
extension String {
    /// Returns the currency symbol based on the selected currency in UserDefaults
    static func currencySymbol() -> String {
        let selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        switch selectedCurrency {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "CAD":
            return "$"
        case "JPY":
            return "¥"
        case "CNY":
            return "¥"
        default:
            return "$"
        }
    }
}

// MARK: - Number Formatting Extensions
extension Double {
    /// Formats numbers to simplified format (1530 -> 1.5k, 1500000 -> 1.5M, 1500000000 -> 1.5B)
    func formattedCurrency() -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        let currencySymbol = String.currencySymbol()

        switch absValue {
        case 1_000_000_000...:
            // Billions
            let billions = absValue / 1_000_000_000
            if billions >= 100 {
                return "\(sign)\(currencySymbol)\(String(format: "%.0f", billions))B"
            } else if billions >= 10 {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", billions))B"
            } else {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", billions))B"
            }
        case 1_000_000...:
            // Millions
            let millions = absValue / 1_000_000
            if millions >= 100 {
                return "\(sign)\(currencySymbol)\(String(format: "%.0f", millions))M"
            } else if millions >= 10 {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", millions))M"
            } else {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", millions))M"
            }
        case 1_000...:
            // Thousands
            let thousands = absValue / 1_000
            if thousands >= 100 {
                return "\(sign)\(currencySymbol)\(String(format: "%.0f", thousands))k"
            } else if thousands >= 10 {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", thousands))k"
            } else {
                return "\(sign)\(currencySymbol)\(String(format: "%.1f", thousands))k"
            }
        default:
            // Under 1000, show normal format
            if absValue >= 100 {
                return "\(sign)\(currencySymbol)\(String(format: "%.0f", absValue))"
            } else {
                return "\(sign)\(currencySymbol)\(String(format: "%.2f", absValue))"
            }
        }
    }

    /// Formats numbers without currency symbol for cases where $ is already present
    func formattedNumber() -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""

        switch absValue {
        case 1_000_000_000...:
            // Billions
            let billions = absValue / 1_000_000_000
            if billions >= 100 {
                return "\(sign)\(String(format: "%.0f", billions))B"
            } else {
                return "\(sign)\(String(format: "%.1f", billions))B"
            }
        case 1_000_000...:
            // Millions
            let millions = absValue / 1_000_000
            if millions >= 100 {
                return "\(sign)\(String(format: "%.0f", millions))M"
            } else {
                return "\(sign)\(String(format: "%.1f", millions))M"
            }
        case 1_000...:
            // Thousands
            let thousands = absValue / 1_000
            if thousands >= 100 {
                return "\(sign)\(String(format: "%.0f", thousands))k"
            } else {
                return "\(sign)\(String(format: "%.1f", thousands))k"
            }
        default:
            // Under 1000, show normal format
            if absValue >= 100 {
                return "\(sign)\(String(format: "%.0f", absValue))"
            } else {
                return "\(sign)\(String(format: "%.2f", absValue))"
            }
        }
    }
}
