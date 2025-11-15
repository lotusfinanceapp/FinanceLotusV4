import SwiftUI

// MARK: - Category Picker Sheet
struct CategoryPickerView: View {
    let categories: [CustomCategory]
    @Binding var selectedCategories: [CustomCategory]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Clear all filters option
                    Button(action: {
                        selectedCategories = []
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.colSecondaryText.opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.colSecondaryText)
                            }

                            Text("Clear All Filters")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.colPrimaryText)

                            Spacer()

                            if selectedCategories.isEmpty {
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

                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        VStack(spacing: 0) {
                            Button(action: {
                                if selectedCategories.contains(where: { $0.id == category.id }) {
                                    selectedCategories.removeAll { $0.id == category.id }
                                } else {
                                    // Only allow adding if less than 4 categories selected
                                    if selectedCategories.count < 4 {
                                        selectedCategories.append(category)
                                    }
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.15))
                                            .frame(width: 40, height: 40)

                                        Image(systemName: category.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(category.color)
                                    }

                                    Text(category.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.colPrimaryText)

                                    if category.isStarred {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                    }

                                    Spacer()

                                    if selectedCategories.contains(where: { $0.id == category.id }) {
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
                            .opacity((selectedCategories.count >= 4 && !selectedCategories.contains(where: { $0.id == category.id })) ? 0.4 : 1.0)

                            // Separator line (except for last item)
                            if index < categories.count - 1 {
                                Rectangle()
                                    .fill(Color.colAccent.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                            }
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
                    Text("Filter by Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
    }
}
