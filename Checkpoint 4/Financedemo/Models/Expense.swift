import Foundation
import SwiftUI

// MARK: - Expense Categories
enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transport = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case health = "Health & Fitness"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .food: return .colCategoryFood
        case .transport: return .colCategoryTransport
        case .shopping: return .colCategoryShopping
        case .entertainment: return .colCategoryEntertainment
        case .bills: return .colCategoryBills
        case .health: return .colCategoryHealth
        case .other: return .colCategoryOther
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .bills: return "creditcard.fill"
        case .health: return "heart.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Expense Model - INDIVIDUAL EXPENSE DATA STRUCTURE
struct Expense: Codable, Identifiable {
    let id: UUID            // Unique identifier for each expense
    let amount: Double      // Amount spent (e.g., 25.50)
    let note: String        // Optional description (e.g., "Lunch", "Movie ticket")
    let date: Date         // When this expense was logged
    let category: ExpenseCategory // Expense category with color and icon (for backward compatibility)
    let customCategory: CustomCategory? // New custom category system
    
    init(amount: Double, note: String, date: Date, category: ExpenseCategory = .other) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.category = category
        self.customCategory = nil
    }
    
    init(amount: Double, note: String, date: Date, customCategory: CustomCategory) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.category = .other // Default fallback for backward compatibility
        self.customCategory = customCategory
    }
    
    // Computed property to get the effective category
    var effectiveCategory: CustomCategory {
        if let customCategory = customCategory {
            return customCategory
        } else {
            // Convert old ExpenseCategory to CustomCategory for backward compatibility
            return category.toCustomCategory()
        }
    }
}