import SwiftUI

// MARK: - Category Edit View - Add/Edit categories with icon and color selection
struct CategoryEditView: View {
    @ObservedObject var categoryManager: CategoryManager
    let existingCategory: CustomCategory?
    @Binding var isPresented: Bool
    
    @State private var categoryName: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String
    @State private var showElements = false
    
    init(categoryManager: CategoryManager, existingCategory: CustomCategory?, isPresented: Binding<Bool>) {
        self.categoryManager = categoryManager
        self.existingCategory = existingCategory
        self._isPresented = isPresented
        
        // Initialize state based on whether we're editing or creating
        if let category = existingCategory {
            self._categoryName = State(initialValue: category.name)
            self._selectedIcon = State(initialValue: category.icon)
            self._selectedColorHex = State(initialValue: category.colorHex)
        } else {
            self._categoryName = State(initialValue: "")
            self._selectedIcon = State(initialValue: "questionmark.circle.fill")
            self._selectedColorHex = State(initialValue: "#95A5A6")
        }
    }
    
    // Available icons for categories
    private let availableIcons = [
        "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill",
        "creditcard.fill", "heart.fill", "questionmark.circle.fill",
        "house.fill", "phone.fill", "book.fill", "music.note",
        "camera.fill", "airplane", "bicycle", "leaf.fill",
        "flame.fill", "drop.fill", "bolt.fill", "tv.fill",
        "sportscourt.fill", "dumbbell.fill", "football.fill", "basketball.fill",
        "tennis.racket", "figure.walk", "bed.double.fill", "cup.and.saucer.fill",
        "gift.fill", "paintbrush.fill", "wrench.and.screwdriver.fill", "stethoscope",
        "graduationcap.fill", "briefcase.fill", "tshirt.fill", "scissors"
    ]
    
    // Available colors for categories
    private let availableColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FECA57", "#FF9FF3", "#95A5A6", "#E74C3C",
        "#3498DB", "#2ECC71", "#F39C12", "#9B59B6",
        "#1ABC9C", "#E67E22", "#34495E", "#F1C40F"
    ]
    
    private var isEditing: Bool {
        existingCategory != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // === HEADER SECTION WITH BACK BUTTON ===
            VStack(spacing: 20) {
                // Back button and title
                HStack {
                    Button(action: {
                        hideKeyboard()
                        isPresented = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colBackButtonIcon)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5), value: showElements)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Title section
                VStack(spacing: 10) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: selectedColorHex))
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)
                    
                    Text(isEditing ? "Edit Category" : "Add Category")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                    
                    Text("Customize name, icon, and color")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
            }
            .padding(.bottom, 30)
            
            // === FORM SECTION ===
            ScrollView {
                VStack(spacing: 25) {
                    // Combined form card with all inputs
                    VStack(alignment: .leading, spacing: 25) {
                        // Category Name Input
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Category Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)
                            
                            TextField("Enter category name", text: $categoryName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.colInputBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.colIconPrimary.opacity(0.3), lineWidth: 1.5)
                                        )
                                )
                        }
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Select Icon")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                                ForEach(Array(availableIcons.enumerated()), id: \.element) { index, icon in
                                    Button(action: {
                                        hideKeyboard()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedIcon = icon
                                        }
                                    }) {
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? Color(hex: selectedColorHex) : .colSecondaryText)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color.clear)
                                            )
                                            .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: selectedIcon == icon)
                                    }
                                    .opacity(showElements ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.3).delay(0.3 + Double(index) * 0.02), value: showElements)
                                }
                            }
                        }
                        
                        // Color Selection with modern indicators
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Select Color")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(Array(availableColors.enumerated()), id: \.element) { index, colorHex in
                                    Button(action: {
                                        hideKeyboard()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedColorHex = colorHex
                                        }
                                    }) {
                                        ZStack {
                                            // Background circle for selection
                                            if selectedColorHex == colorHex {
                                                Circle()
                                                    .fill(Color.colAccent.opacity(0.3))
                                                    .frame(width: 40, height: 40)
                                            }
                                            
                                            // Main color circle
                                            Circle()
                                                .fill(Color(hex: colorHex))
                                                .frame(width: 32, height: 32)
                                        }
                                        .scaleEffect(selectedColorHex == colorHex ? 1.05 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedColorHex == colorHex)
                                    }
                                    .opacity(showElements ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.3).delay(0.4 + Double(index) * 0.02), value: showElements)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 25)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.colCardBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 30)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    
                    // Save button at bottom
                    Button(action: {
                        hideKeyboard()
                        saveCategory()
                    }) {
                        Text(isEditing ? "Update Category" : "Add Category")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.colGradient2, .colGradient1]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(categoryName.isEmpty)
                    .opacity(categoryName.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: showElements)
                    
                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            showElements = false
            withAnimation {
                showElements = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveCategory() {
        guard !categoryName.isEmpty else { return }
        
        if let existingCategory = existingCategory {
            // Edit existing category
            categoryManager.editCategory(existingCategory, name: categoryName, icon: selectedIcon, colorHex: selectedColorHex)
        } else {
            // Add new category
            categoryManager.addCategory(name: categoryName, icon: selectedIcon, colorHex: selectedColorHex)
        }
        
        isPresented = false
    }
}

// MARK: - Preview
#if DEBUG
struct CategoryEditView_Previews: PreviewProvider {
    @State static var isPresented = true
    
    static var previews: some View {
        CategoryEditView(
            categoryManager: CategoryManager(),
            existingCategory: nil,
            isPresented: $isPresented
        )
        .previewDisplayName("Add Category")
        
        CategoryEditView(
            categoryManager: CategoryManager(),
            existingCategory: CustomCategory(name: "Test", icon: "heart.fill", colorHex: "#FF6B6B"),
            isPresented: $isPresented
        )
        .previewDisplayName("Edit Category")
    }
}
#endif