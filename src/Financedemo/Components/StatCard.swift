import SwiftUI

// MARK: - Stat Card Component - REUSABLE CARD FOR DISPLAYING STATISTICS
struct StatCard: View {
    let title: String    // Card title (e.g., "Budget", "Spent", "Remaining")
    let value: String    // Card value (e.g., "$100.00")
    let color: Color     // Card color theme (determines text and background colors)
    
    var body: some View {
        VStack(spacing: 8) {
            // Card title text
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.colSecondaryText)
            
            // Card value text (colored with the provided color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)        // Fill available width
        .padding()                         // Internal spacing
        .background(Color.colCardBackground)    // Black background to match app theme
        .cornerRadius(12)                  // Rounded corners
    }
}

// MARK: - Preview
#if DEBUG
struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        StatCard(title: "Budget", value: "$100.00", color: .blue)
            .previewDisplayName("Stat Card")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif