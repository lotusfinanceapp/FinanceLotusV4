import SwiftUI

// MARK: - Sort Picker Sheet
struct SortPickerView: View {
    @Binding var selectedSort: AllExpensesView.SortOption
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(AllExpensesView.SortOption.allCases, id: \.self) { sortOption in
                        Button(action: {
                            selectedSort = sortOption
                            isPresented = false
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.colAccent.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: sortOption.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.colAccent)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sortOption.rawValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)

                                    Text({
                                        switch sortOption {
                                        case .date: return "Newest to oldest"
                                        case .category: return "Alphabetical order"
                                        case .amount: return "Highest to lowest"
                                        }
                                    }())
                                        .font(.caption)
                                        .foregroundColor(.colSecondaryText)
                                }

                                Spacer()

                                if selectedSort == sortOption {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.colAccent)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Separator line (except for last item)
                        if sortOption != AllExpensesView.SortOption.allCases.last {
                            Rectangle()
                                .fill(Color.colAccent.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.colBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.colBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.colAccent)
                    }
                }

                // NOTE: Always use ToolbarItem(placement: .principal) with .foregroundColor(.colPrimaryText)
                // for navigation titles instead of .navigationTitle() + .toolbarColorScheme(.dark)
                ToolbarItem(placement: .principal) {
                    Text("Sort Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
    }
}
