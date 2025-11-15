import Foundation
import SwiftUI

// MARK: - Budget Period Options
enum BudgetPeriod: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"  
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var description: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar.circle"
        case .yearly: return "calendar.badge.exclamationmark"
        }
    }
}

// MARK: - Spending Status Enum
enum SpendingStatus: String, CaseIterable {
    case underBudget = "Under Budget"
    case onTrack = "On Track"
    case overBudget = "Over Budget"
    
    var color: Color {
        switch self {
        case .underBudget: return .green
        case .onTrack: return .blue
        case .overBudget: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .underBudget: return "arrow.down.circle.fill"
        case .onTrack: return "checkmark.circle.fill"  
        case .overBudget: return "exclamationmark.triangle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .underBudget: return "You're spending less than expected - great job!"
        case .onTrack: return "You're right on track with your budget goals"
        case .overBudget: return "You're spending more than planned - consider adjusting"
        }
    }
}

// MARK: - Budget Model - CORE BUDGET DATA STRUCTURE
struct Budget: Codable, Identifiable {
    let id: UUID
    let amount: Double       // Budget amount (e.g., $100.00)
    let period: BudgetPeriod // Budget time period (daily/weekly/monthly/yearly)
    let month: Int           // Month (1-12) this budget applies to
    let year: Int            // Year this budget applies to
    let dateCreated: Date    // When this budget was created

    init(amount: Double, period: BudgetPeriod, month: Int, year: Int, dateCreated: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.period = period
        self.month = month
        self.year = year
        self.dateCreated = dateCreated
    }
}