import SwiftUI

// MARK: - Unified Stat Card Component
// This component replaces both InsightCard and DetailedStatCard for consistency
struct UnifiedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: (() -> Void)?

    // Convenience initializer for cards without selection/tap functionality
    init(title: String, value: String, subtitle: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isSelected = false
        self.onTap = nil
    }

    // Full initializer for interactive cards (like DetailedStatCard)
    init(title: String, value: String, subtitle: String, icon: String, color: Color, isSelected: Bool, onTap: @escaping () -> Void) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 8) {
            // Main title at the top
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.colPrimaryText)

            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.colSecondaryText)
                    .lineLimit(1)

                Spacer()
            }

            // Value (amount/number)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? color.opacity(0.3) : color.opacity(0.1))
                .animation(.easeInOut(duration: 0.3), value: isSelected)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? color.opacity(0.6) : color.opacity(0.3), lineWidth: 1)
                .animation(.easeInOut(duration: 0.3), value: isSelected)
        )

        // Return either interactive button or static view
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
}

// MARK: - Preview
#if DEBUG
struct UnifiedStatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Static card (like InsightCard)
            UnifiedStatCard(
                title: "Trend",
                value: "-$23",
                subtitle: "Yesterday vs Today",
                icon: "chart.line.downtrend.xyaxis",
                color: .blue
            )

            // Interactive card (like DetailedStatCard)
            UnifiedStatCard(
                title: "Most Spent",
                value: "$45",
                subtitle: "Food",
                icon: "fork.knife",
                color: .green,
                isSelected: true,
                onTap: {}
            )
        }
        .padding()
        .background(Color.colBackground)
    }
}
#endif