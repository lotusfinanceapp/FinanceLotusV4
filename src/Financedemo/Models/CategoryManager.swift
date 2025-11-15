import Foundation
import SwiftUI

// MARK: - Subcategory Model
struct Subcategory: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var defaultAmount: Double? // Optional default amount for this subcategory
    var lastUsed: Date? // Track when this subcategory was last used

    init(name: String, defaultAmount: Double? = nil, lastUsed: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.defaultAmount = defaultAmount
        self.lastUsed = lastUsed
    }
}

// MARK: - Custom Category Model
struct CustomCategory: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isDefault: Bool // Whether this is a built-in category
    var isStarred: Bool // Whether this category is starred for priority
    var starOrder: TimeInterval? // Timestamp when starred (for sorting)
    var subcategories: [Subcategory] // Subcategories for this category

    init(name: String, icon: String, colorHex: String, isDefault: Bool = false, isStarred: Bool = false, starOrder: TimeInterval? = nil, subcategories: [Subcategory] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.isStarred = isStarred
        self.starOrder = starOrder
        self.subcategories = subcategories
    }

    var color: Color {
        return Color(hex: colorHex)
    }

    // Static method to convert ExpenseCategory to CustomCategory
    static func fromExpenseCategory(_ category: ExpenseCategory) -> CustomCategory {
        switch category {
        case .food:
            return CustomCategory(name: "Food", icon: "fork.knife", colorHex: "#FF6B6B", isDefault: true)
        case .transport:
            return CustomCategory(name: "Transport", icon: "car.fill", colorHex: "#4ECDC4", isDefault: true)
        case .entertainment:
            return CustomCategory(name: "Entertainment", icon: "tv.fill", colorHex: "#45B7D1", isDefault: true)
        case .shopping:
            return CustomCategory(name: "Shopping", icon: "bag.fill", colorHex: "#96CEB4", isDefault: true)
        case .bills:
            return CustomCategory(name: "Bills", icon: "doc.text.fill", colorHex: "#FFB347", isDefault: true)
        case .health:
            return CustomCategory(name: "Health", icon: "heart.fill", colorHex: "#FFEAA7", isDefault: true)
        case .other:
            return CustomCategory(name: "Other", icon: "questionmark.circle.fill", colorHex: "#DDA0DD", isDefault: true)
        }
    }
}

// MARK: - Category Manager - Handles both default and custom categories
class CategoryManager: ObservableObject {
    @Published var customCategories: [CustomCategory] = []
    
    private let userDefaults = UserDefaults.standard
    private let customCategoriesKey = "customCategories"
    private let defaultCategoriesKey = "defaultCategories"
    
    @Published var defaultCategories: [CustomCategory] = []
    
    // All categories (default + custom), with starred categories first sorted by most recent
    var allCategories: [CustomCategory] {
        let allCats = defaultCategories + customCategories
        let starred = allCats.filter { $0.isStarred }.sorted {
            ($0.starOrder ?? 0) > ($1.starOrder ?? 0) // Most recent first
        }
        let unstarred = allCats.filter { !$0.isStarred }
        return starred + unstarred
    }
    
    init() {
        loadDefaultCategories()
        loadCustomCategories()
    }
    
    // MARK: - Default Category Setup
    private func initializeDefaultCategories() {
        defaultCategories = [
            CustomCategory(name: "Food & Dining", icon: "fork.knife", colorHex: "#FF6B6B", isDefault: true),
            CustomCategory(name: "Transportation", icon: "car.fill", colorHex: "#4ECDC4", isDefault: true),
            CustomCategory(name: "Shopping", icon: "bag.fill", colorHex: "#45B7D1", isDefault: true),
            CustomCategory(name: "Entertainment", icon: "gamecontroller.fill", colorHex: "#96CEB4", isDefault: true),
            CustomCategory(name: "Bills & Utilities", icon: "creditcard.fill", colorHex: "#FECA57", isDefault: true),
            CustomCategory(name: "Health & Fitness", icon: "heart.fill", colorHex: "#FF9FF3", isDefault: true),
            CustomCategory(name: "Other", icon: "questionmark.circle.fill", colorHex: "#95A5A6", isDefault: true)
        ]
        saveDefaultCategories()
    }
    
    // MARK: - Persistence
    private func loadDefaultCategories() {
        if let data = userDefaults.data(forKey: defaultCategoriesKey),
           let categories = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            self.defaultCategories = categories
        } else {
            // First time launch - initialize with default categories
            initializeDefaultCategories()
        }
    }
    
    private func saveDefaultCategories() {
        if let data = try? JSONEncoder().encode(defaultCategories) {
            userDefaults.set(data, forKey: defaultCategoriesKey)
        }
    }
    
    private func loadCustomCategories() {
        if let data = userDefaults.data(forKey: customCategoriesKey),
           let categories = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            self.customCategories = categories
        }
    }
    
    private func saveCustomCategories() {
        if let data = try? JSONEncoder().encode(customCategories) {
            userDefaults.set(data, forKey: customCategoriesKey)
        }
    }
    
    // MARK: - Category Management
    func addCategory(name: String, icon: String, colorHex: String) {
        let newCategory = CustomCategory(name: name, icon: icon, colorHex: colorHex)
        customCategories.append(newCategory)
        saveCustomCategories()
    }
    
    func editCategory(_ category: CustomCategory, name: String, icon: String, colorHex: String) {
        if category.isDefault {
            // Edit default category
            if let index = defaultCategories.firstIndex(where: { $0.id == category.id }) {
                defaultCategories[index].name = name
                defaultCategories[index].icon = icon
                defaultCategories[index].colorHex = colorHex
                saveDefaultCategories()
            }
        } else {
            // Edit custom category
            if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
                customCategories[index].name = name
                customCategories[index].icon = icon
                customCategories[index].colorHex = colorHex
                saveCustomCategories()
            }
        }
    }
    
    func deleteCategory(_ category: CustomCategory, dataManager: BudgetDataManager? = nil) {
        // Delete all expenses associated with this category
        if let dataManager = dataManager {
            dataManager.deleteExpensesForCategory(category.id)
        }

        // Delete the category itself (can be default or custom)
        if category.isDefault {
            defaultCategories.removeAll { $0.id == category.id }
            saveDefaultCategories()
        } else {
            customCategories.removeAll { $0.id == category.id }
            saveCustomCategories()
        }
    }
    
    func toggleStar(for category: CustomCategory) -> Bool {
        let currentlyStarred = allCategories.filter { $0.isStarred }

        // If trying to star a category and already have 5 starred, don't allow it
        if !category.isStarred && currentlyStarred.count >= 5 {
            return false // Return false to indicate the action was blocked
        }

        if category.isDefault {
            // Toggle star for default category
            if let index = defaultCategories.firstIndex(where: { $0.id == category.id }) {
                defaultCategories[index].isStarred.toggle()
                // Set starOrder to current timestamp when starring, nil when unstarring
                if defaultCategories[index].isStarred {
                    defaultCategories[index].starOrder = Date().timeIntervalSince1970
                } else {
                    defaultCategories[index].starOrder = nil
                }
                saveDefaultCategories()
            }
        } else {
            // Toggle star for custom category
            if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
                customCategories[index].isStarred.toggle()
                // Set starOrder to current timestamp when starring, nil when unstarring
                if customCategories[index].isStarred {
                    customCategories[index].starOrder = Date().timeIntervalSince1970
                } else {
                    customCategories[index].starOrder = nil
                }
                saveCustomCategories()
            }
        }
        return true // Return true to indicate success
    }
    
    // MARK: - Subcategory Management
    func addSubcategory(to category: CustomCategory, subcategoryName: String, defaultAmount: Double? = nil) {
        let newSubcategory = Subcategory(name: subcategoryName, defaultAmount: defaultAmount)

        if category.isDefault {
            if let index = defaultCategories.firstIndex(where: { $0.id == category.id }) {
                defaultCategories[index].subcategories.append(newSubcategory)
                saveDefaultCategories()
            }
        } else {
            if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
                customCategories[index].subcategories.append(newSubcategory)
                saveCustomCategories()
            }
        }
    }

    func deleteSubcategory(_ subcategory: Subcategory, from category: CustomCategory) {
        if category.isDefault {
            if let index = defaultCategories.firstIndex(where: { $0.id == category.id }) {
                defaultCategories[index].subcategories.removeAll { $0.id == subcategory.id }
                saveDefaultCategories()
            }
        } else {
            if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
                customCategories[index].subcategories.removeAll { $0.id == subcategory.id }
                saveCustomCategories()
            }
        }
    }

    func updateSubcategory(_ subcategory: Subcategory, in category: CustomCategory, newName: String, newDefaultAmount: Double?, dataManager: BudgetDataManager?) {
        let oldName = subcategory.name

        if category.isDefault {
            if let categoryIndex = defaultCategories.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = defaultCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                defaultCategories[categoryIndex].subcategories[subcategoryIndex].name = newName
                defaultCategories[categoryIndex].subcategories[subcategoryIndex].defaultAmount = newDefaultAmount
                saveDefaultCategories()
            }
        } else {
            if let categoryIndex = customCategories.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = customCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                customCategories[categoryIndex].subcategories[subcategoryIndex].name = newName
                customCategories[categoryIndex].subcategories[subcategoryIndex].defaultAmount = newDefaultAmount
                saveCustomCategories()
            }
        }

        // Update all existing expenses and recurring expenses with the new subcategory name
        if let dataManager = dataManager {
            dataManager.updateSubcategoryName(oldName: oldName, newName: newName, categoryId: category.id)
        }
    }

    func getSubcategories(for category: CustomCategory) -> [Subcategory] {
        if let foundCategory = allCategories.first(where: { $0.id == category.id }) {
            // Sort by most recently used first
            return foundCategory.subcategories.sorted { (sub1, sub2) in
                // If both have lastUsed, sort by most recent
                if let date1 = sub1.lastUsed, let date2 = sub2.lastUsed {
                    return date1 > date2
                }
                // If only one has lastUsed, it goes first
                if sub1.lastUsed != nil {
                    return true
                }
                if sub2.lastUsed != nil {
                    return false
                }
                // If neither has been used, maintain original order
                return false
            }
        }
        return []
    }

    func markSubcategoryAsUsed(_ subcategory: Subcategory, in category: CustomCategory) {
        if category.isDefault {
            if let categoryIndex = defaultCategories.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = defaultCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                defaultCategories[categoryIndex].subcategories[subcategoryIndex].lastUsed = Date()
                saveDefaultCategories()
            }
        } else {
            if let categoryIndex = customCategories.firstIndex(where: { $0.id == category.id }),
               let subcategoryIndex = customCategories[categoryIndex].subcategories.firstIndex(where: { $0.id == subcategory.id }) {
                customCategories[categoryIndex].subcategories[subcategoryIndex].lastUsed = Date()
                saveCustomCategories()
            }
        }
    }

    // MARK: - Helper Methods
    func getCategoryByName(_ name: String) -> CustomCategory? {
        return allCategories.first { $0.name == name }
    }
    
    func getDefaultCategoryForOldExpenseCategory(_ oldCategory: ExpenseCategory) -> CustomCategory {
        // Find matching category by name first, then fallback to index
        switch oldCategory {
        case .food: 
            return defaultCategories.first { $0.name == "Food & Dining" } ?? defaultCategories.first ?? CustomCategory(name: "Food & Dining", icon: "fork.knife", colorHex: "#FF6B6B", isDefault: true)
        case .transport: 
            return defaultCategories.first { $0.name == "Transportation" } ?? defaultCategories.first ?? CustomCategory(name: "Transportation", icon: "car.fill", colorHex: "#4ECDC4", isDefault: true)
        case .shopping: 
            return defaultCategories.first { $0.name == "Shopping" } ?? defaultCategories.first ?? CustomCategory(name: "Shopping", icon: "bag.fill", colorHex: "#45B7D1", isDefault: true)
        case .entertainment: 
            return defaultCategories.first { $0.name == "Entertainment" } ?? defaultCategories.first ?? CustomCategory(name: "Entertainment", icon: "gamecontroller.fill", colorHex: "#96CEB4", isDefault: true)
        case .bills: 
            return defaultCategories.first { $0.name == "Bills & Utilities" } ?? defaultCategories.first ?? CustomCategory(name: "Bills & Utilities", icon: "creditcard.fill", colorHex: "#FECA57", isDefault: true)
        case .health: 
            return defaultCategories.first { $0.name == "Health & Fitness" } ?? defaultCategories.first ?? CustomCategory(name: "Health & Fitness", icon: "heart.fill", colorHex: "#FF9FF3", isDefault: true)
        case .other: 
            return defaultCategories.first { $0.name == "Other" } ?? defaultCategories.first ?? CustomCategory(name: "Other", icon: "questionmark.circle.fill", colorHex: "#95A5A6", isDefault: true)
        }
    }
}

// MARK: - Extension for backwards compatibility with ExpenseCategory enum
extension ExpenseCategory {
    func toCustomCategory() -> CustomCategory {
        switch self {
        case .food: return CustomCategory(name: "Food & Dining", icon: "fork.knife", colorHex: "#FF6B6B", isDefault: true)
        case .transport: return CustomCategory(name: "Transportation", icon: "car.fill", colorHex: "#4ECDC4", isDefault: true)
        case .shopping: return CustomCategory(name: "Shopping", icon: "bag.fill", colorHex: "#45B7D1", isDefault: true)
        case .entertainment: return CustomCategory(name: "Entertainment", icon: "gamecontroller.fill", colorHex: "#96CEB4", isDefault: true)
        case .bills: return CustomCategory(name: "Bills & Utilities", icon: "creditcard.fill", colorHex: "#FECA57", isDefault: true)
        case .health: return CustomCategory(name: "Health & Fitness", icon: "heart.fill", colorHex: "#FF9FF3", isDefault: true)
        case .other: return CustomCategory(name: "Other", icon: "questionmark.circle.fill", colorHex: "#95A5A6", isDefault: true)
        }
    }
}