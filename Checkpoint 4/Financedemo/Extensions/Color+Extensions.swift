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
    
    // === THEME APPLICATION FUNCTION ===
    static func applyTheme(_ theme: ThemeManager.AppTheme) {
        print("DEBUG: Applying theme: \(theme.rawValue)")
        switch theme {
        case .original:
            // Original green theme
            _colBackground = Color(hex: "#388E3C")
            _colGradient1 = Color(hex: "#FADADD")
            _colGradient2 = Color(hex: "#9CCC65")
            _colButton = Color(hex: "#689F38")
            _colIconPrimary = Color(hex: "#9CCC65")
            _colIconSecondary = Color(hex: "#FADADD")
            _colExpenseBackground = Color(hex: "#9CCC65")
            _colExpenseText = Color(hex: "#C62828")
            _colProgressTrack = Color(hex: "#9CCC65")
            _colProgressFill1 = Color(hex: "#FADADD")
            _colProgressFill2 = Color(hex: "#9CCC65")
            _colStatBudget = Color(hex: "#66BB6A")
            _colStatSpent = Color(hex: "#66BB6A")
            _colStatRemaining = Color(hex: "#66BB6A")
            _colAlertText = Color(hex: "#C62828")
            _colAlertBackground = Color(hex: "#FADADD")
            _colCardBackground = Color(hex: "#68BC6C")
            _colInputBackground = Color(hex: "#8FD194")
            _colAccent = Color(hex: "#9CCC65")
            _colButtonText = Color(hex: "#FADADD")
            _colRemainingText = Color(hex: "#A8C0A0")
            _colBackButtonIcon = Color(hex: "#9CCC65")
            _colCalendarIcon = Color(hex: "#9CCC65")
            _colChartIcon = Color(hex: "#9CCC65")
            _colDollarIcon = Color(hex: "#eeb501")
            _colTargetIcon = Color(hex: "#9CCC65")
            _colPieChartIcon = Color(hex: "#9CCC65")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
            
        case .lotus:
            // Lotus pink & green theme
            _colBackground = Color(hex: "#F9F4F6")
            _colGradient1 = Color(hex: "#F2C2D4")
            _colGradient2 = Color(hex: "#A8D5A8")
            _colButton = Color(hex: "#7DB87D")
            _colIconPrimary = Color(hex: "#7DB87D")
            _colIconSecondary = Color(hex: "#F2C2D4")
            _colExpenseBackground = Color(hex: "#F5E6ED")
            _colExpenseText = Color(hex: "#C66B85")
            _colProgressTrack = Color(hex: "#E8F5E8")
            _colProgressFill1 = Color(hex: "#F2C2D4")
            _colProgressFill2 = Color(hex: "#7DB87D")
            _colStatBudget = Color(hex: "#7DB87D")
            _colStatSpent = Color(hex: "#D498A7")
            _colStatRemaining = Color(hex: "#7DB87D")
            _colAlertText = Color(hex: "#C66B85")
            _colAlertBackground = Color(hex: "#F5E6ED")
            _colCardBackground = Color(hex: "#F0DDE6")
            _colInputBackground = Color(hex: "#F5E6ED")
            _colAccent = Color(hex: "#7DB87D")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#7DB87D")
            _colBackButtonIcon = Color(hex: "#7DB87D")
            _colCalendarIcon = Color(hex: "#D498A7")
            _colChartIcon = Color(hex: "#7DB87D")
            _colDollarIcon = Color(hex: "#F4A460")
            _colTargetIcon = Color(hex: "#7DB87D")
            _colPieChartIcon = Color(hex: "#D498A7")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
            
        case .ocean:
            // Ocean blue theme - clean blues and whites
            _colBackground = Color(hex: "#F0F8FF")
            _colGradient1 = Color(hex: "#E3F2FD")
            _colGradient2 = Color(hex: "#64B5F6")
            _colButton = Color(hex: "#2196F3")
            _colIconPrimary = Color(hex: "#1976D2")
            _colIconSecondary = Color(hex: "#BBDEFB")
            _colExpenseBackground = Color(hex: "#E8F4FD")
            _colExpenseText = Color(hex: "#0D47A1")
            _colProgressTrack = Color(hex: "#E3F2FD")
            _colProgressFill1 = Color(hex: "#64B5F6")
            _colProgressFill2 = Color(hex: "#1976D2")
            _colStatBudget = Color(hex: "#1976D2")
            _colStatSpent = Color(hex: "#42A5F5")
            _colStatRemaining = Color(hex: "#1976D2")
            _colAlertText = Color(hex: "#0D47A1")
            _colAlertBackground = Color(hex: "#E8F4FD")
            _colCardBackground = Color(hex: "#E1F5FE")
            _colInputBackground = Color(hex: "#F0F8FF")
            _colAccent = Color(hex: "#1976D2")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#1976D2")
            _colBackButtonIcon = Color(hex: "#1976D2")
            _colCalendarIcon = Color(hex: "#42A5F5")
            _colChartIcon = Color(hex: "#1976D2")
            _colDollarIcon = Color(hex: "#FFC107")
            _colTargetIcon = Color(hex: "#1976D2")
            _colPieChartIcon = Color(hex: "#42A5F5")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
            
        case .sunset:
            // Sunset orange theme - warm oranges and corals
            _colBackground = Color(hex: "#FFF8F5")
            _colGradient1 = Color(hex: "#FFCCBC")
            _colGradient2 = Color(hex: "#FFAB91")
            _colButton = Color(hex: "#FF7043")
            _colIconPrimary = Color(hex: "#FF5722")
            _colIconSecondary = Color(hex: "#FFCCBC")
            _colExpenseBackground = Color(hex: "#FFF3E0")
            _colExpenseText = Color(hex: "#D84315")
            _colProgressTrack = Color(hex: "#FFE0B2")
            _colProgressFill1 = Color(hex: "#FFAB91")
            _colProgressFill2 = Color(hex: "#FF5722")
            _colStatBudget = Color(hex: "#FF5722")
            _colStatSpent = Color(hex: "#FF7043")
            _colStatRemaining = Color(hex: "#FF5722")
            _colAlertText = Color(hex: "#D84315")
            _colAlertBackground = Color(hex: "#FFF3E0")
            _colCardBackground = Color(hex: "#FFE0B2")
            _colInputBackground = Color(hex: "#FFF8F5")
            _colAccent = Color(hex: "#FF5722")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#FF5722")
            _colBackButtonIcon = Color(hex: "#FF5722")
            _colCalendarIcon = Color(hex: "#FF7043")
            _colChartIcon = Color(hex: "#FF5722")
            _colDollarIcon = Color(hex: "#FFC107")
            _colTargetIcon = Color(hex: "#FF5722")
            _colPieChartIcon = Color(hex: "#FF7043")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
            
        case .midnight:
            // Midnight dark theme - sleek dark with blue accents
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
            _colPercentageText = Color.white
            _colEmptyStateText = Color(hex: "#B3B3B3")
            
        case .lavender:
            // Lavender purple theme - elegant purples and soft whites
            _colBackground = Color(hex: "#FAF8FF")
            _colGradient1 = Color(hex: "#F3E5F5")
            _colGradient2 = Color(hex: "#CE93D8")
            _colButton = Color(hex: "#9C27B0")
            _colIconPrimary = Color(hex: "#7B1FA2")
            _colIconSecondary = Color(hex: "#E1BEE7")
            _colExpenseBackground = Color(hex: "#F8F5FF")
            _colExpenseText = Color(hex: "#4A148C")
            _colProgressTrack = Color(hex: "#F3E5F5")
            _colProgressFill1 = Color(hex: "#CE93D8")
            _colProgressFill2 = Color(hex: "#7B1FA2")
            _colStatBudget = Color(hex: "#7B1FA2")
            _colStatSpent = Color(hex: "#BA68C8")
            _colStatRemaining = Color(hex: "#7B1FA2")
            _colAlertText = Color(hex: "#4A148C")
            _colAlertBackground = Color(hex: "#F8F5FF")
            _colCardBackground = Color(hex: "#F3E5F5")
            _colInputBackground = Color(hex: "#FAF8FF")
            _colAccent = Color(hex: "#7B1FA2")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#7B1FA2")
            _colBackButtonIcon = Color(hex: "#7B1FA2")
            _colCalendarIcon = Color(hex: "#BA68C8")
            _colChartIcon = Color(hex: "#7B1FA2")
            _colDollarIcon = Color(hex: "#FF9800")
            _colTargetIcon = Color(hex: "#7B1FA2")
            _colPieChartIcon = Color(hex: "#BA68C8")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
            
        case .mint:
            // Fresh mint theme - mint greens and crisp whites
            _colBackground = Color(hex: "#F0FFFF")
            _colGradient1 = Color(hex: "#E0F7FA")
            _colGradient2 = Color(hex: "#4DD0E1")
            _colButton = Color(hex: "#00BCD4")
            _colIconPrimary = Color(hex: "#0097A7")
            _colIconSecondary = Color(hex: "#B2EBF2")
            _colExpenseBackground = Color(hex: "#E8F8F8")
            _colExpenseText = Color(hex: "#006064")
            _colProgressTrack = Color(hex: "#E0F7FA")
            _colProgressFill1 = Color(hex: "#4DD0E1")
            _colProgressFill2 = Color(hex: "#0097A7")
            _colStatBudget = Color(hex: "#0097A7")
            _colStatSpent = Color(hex: "#26C6DA")
            _colStatRemaining = Color(hex: "#0097A7")
            _colAlertText = Color(hex: "#006064")
            _colAlertBackground = Color(hex: "#E8F8F8")
            _colCardBackground = Color(hex: "#E0F7FA")
            _colInputBackground = Color(hex: "#F0FFFF")
            _colAccent = Color(hex: "#0097A7")
            _colButtonText = Color(hex: "#FFFFFF")
            _colRemainingText = Color(hex: "#0097A7")
            _colBackButtonIcon = Color(hex: "#0097A7")
            _colCalendarIcon = Color(hex: "#26C6DA")
            _colChartIcon = Color(hex: "#0097A7")
            _colDollarIcon = Color(hex: "#FF9800")
            _colTargetIcon = Color(hex: "#0097A7")
            _colPieChartIcon = Color(hex: "#26C6DA")
            _colPrimaryText = Color.primary
            _colSecondaryText = Color.secondary
            _colPercentageText = Color.primary
            _colEmptyStateText = Color.secondary
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
    
    // === DYNAMIC TEXT COLORS ===  
    private static var _colPercentageText = Color.primary
    private static var _colEmptyStateText = Color.secondary
    
    static var colPercentageText: Color { _colPercentageText }    // Percentage text in circle center
    static var colEmptyStateText: Color { _colEmptyStateText }    // "No budget set" text
    
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

// MARK: - Number Formatting Extensions
extension Double {
    /// Formats numbers to simplified format (1530 -> 1.5k, 1500000 -> 1.5M, 1500000000 -> 1.5B)
    func formattedCurrency() -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch absValue {
        case 1_000_000_000...:
            // Billions
            let billions = absValue / 1_000_000_000
            if billions >= 100 {
                return "\(sign)$\(String(format: "%.0f", billions))B"
            } else if billions >= 10 {
                return "\(sign)$\(String(format: "%.1f", billions))B"
            } else {
                return "\(sign)$\(String(format: "%.1f", billions))B"
            }
        case 1_000_000...:
            // Millions
            let millions = absValue / 1_000_000
            if millions >= 100 {
                return "\(sign)$\(String(format: "%.0f", millions))M"
            } else if millions >= 10 {
                return "\(sign)$\(String(format: "%.1f", millions))M"
            } else {
                return "\(sign)$\(String(format: "%.1f", millions))M"
            }
        case 1_000...:
            // Thousands
            let thousands = absValue / 1_000
            if thousands >= 100 {
                return "\(sign)$\(String(format: "%.0f", thousands))k"
            } else if thousands >= 10 {
                return "\(sign)$\(String(format: "%.1f", thousands))k"
            } else {
                return "\(sign)$\(String(format: "%.1f", thousands))k"
            }
        default:
            // Under 1000, show normal format
            if absValue >= 100 {
                return "\(sign)$\(String(format: "%.0f", absValue))"
            } else {
                return "\(sign)$\(String(format: "%.2f", absValue))"
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
