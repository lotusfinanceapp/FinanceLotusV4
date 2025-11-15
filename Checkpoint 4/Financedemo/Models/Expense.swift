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
    let customCategory: CustomCategory? // New custom category system (deprecated - kept for decoding old data)
    let categoryId: UUID? // ID reference to the category (new approach)
    let recurringExpenseId: UUID? // ID of the recurring expense that created this expense (if any)

    init(amount: Double, note: String, date: Date, category: ExpenseCategory = .other, recurringExpenseId: UUID? = nil) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.category = category
        self.customCategory = nil
        self.categoryId = nil
        self.recurringExpenseId = recurringExpenseId
    }

    init(amount: Double, note: String, date: Date, customCategory: CustomCategory, recurringExpenseId: UUID? = nil) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.category = .other // Default fallback for backward compatibility
        self.customCategory = customCategory
        self.categoryId = customCategory.id
        self.recurringExpenseId = recurringExpenseId
    }

    init(amount: Double, note: String, date: Date, categoryId: UUID, recurringExpenseId: UUID? = nil) {
        self.id = UUID()
        self.amount = amount
        self.note = note
        self.date = date
        self.category = .other
        self.customCategory = nil
        self.categoryId = categoryId
        self.recurringExpenseId = recurringExpenseId
    }

    // Method to get the effective category with dynamic lookup
    func effectiveCategory(from categoryManager: CategoryManager) -> CustomCategory {
        // First try to look up by ID (new approach)
        if let categoryId = categoryId,
           let liveCategory = categoryManager.allCategories.first(where: { $0.id == categoryId }) {
            return liveCategory
        }

        // Fallback to stored customCategory (for old expenses)
        if let customCategory = customCategory {
            // Try to find updated version by ID
            if let updated = categoryManager.allCategories.first(where: { $0.id == customCategory.id }) {
                return updated
            }
            return customCategory
        }

        // Final fallback to old ExpenseCategory system
        return category.toCustomCategory()
    }

    // Backward-compatible computed property for easy access
    // NOTE: This uses a static CategoryManager, so it won't reflect live updates
    // Use effectiveCategory(from:) method for dynamic updates
    var effectiveCategory: CustomCategory {
        // For backward compatibility, create a temporary CategoryManager
        // This is not ideal but maintains compatibility with existing code
        let tempManager = CategoryManager()
        return effectiveCategory(from: tempManager)
    }
}