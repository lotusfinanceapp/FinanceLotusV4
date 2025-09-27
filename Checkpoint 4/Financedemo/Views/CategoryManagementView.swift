import SwiftUI

// MARK: - Category Management View - Manage categories and their colors/icons
struct CategoryManagementView: View {
    @ObservedObject var categoryManager: CategoryManager
    let dataManager: BudgetDataManager?
    @State private var showingAddCategory = false
    @State private var categoryToEdit: CustomCategory?
    @State private var categoryToDelete: CustomCategory?
    @State private var showingDeleteConfirmation = false
    @State private var deletingCategoryId: UUID? = nil
    @State private var showElements = false
    @State private var showingStarLimitAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // === HEADER SECTION ===
            VStack(spacing: 20) {
                // Back button and title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colBackButtonIcon)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5), value: showElements)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.colAccent)
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Title
                VStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.colAccent)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)
                    
                    Text("Manage Categories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)
                    
                    Text("Customize colors, icons, and add new categories")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .offset(y: showElements ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
            }
            .padding(.bottom, 20)
            
            // === CATEGORIES LIST ===
            ScrollView {
                LazyVStack(spacing: 15) {
                    // Default categories section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Default Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)
                            .opacity(showElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                        
                        ForEach(Array(categoryManager.allCategories.filter { $0.isDefault }.enumerated()), id: \.element.id) { index, category in
                            CategoryRowView(
                                category: category,
                                canDelete: false,
                                canEdit: false,
                                onEdit: {},
                                onDelete: {},
                                onToggleStar: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        let success = categoryManager.toggleStar(for: category)
                                        if !success {
                                            showingStarLimitAlert = true
                                        }
                                    }
                                }
                            )
                            .opacity(showElements ? 1.0 : 0.0)
                            .offset(y: showElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(0.3 + Double(index) * 0.1), value: showElements)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                            ))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: category.isStarred)
                        }
                    }
                    
                    // Custom categories section
                    if !categoryManager.customCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Custom Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.colPrimaryText)
                                .opacity(showElements ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: showElements)
                            
                            ForEach(Array(categoryManager.customCategories.enumerated()), id: \.element.id) { index, category in
                                CategoryRowView(
                                    category: category,
                                    canDelete: true,
                                    canEdit: true,
                                    onEdit: {
                                        categoryToEdit = category
                                    },
                                    onDelete: {
                                        categoryToDelete = category
                                        showingDeleteConfirmation = true
                                    },
                                    onToggleStar: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            let success = categoryManager.toggleStar(for: category)
                                            if !success {
                                                showingStarLimitAlert = true
                                            }
                                        }
                                    }
                                )
                                .opacity(deletingCategoryId == category.id ? 0.0 : (showElements ? 1.0 : 0.0))
                                .scaleEffect(deletingCategoryId == category.id ? 0.8 : 1.0)
                                .offset(
                                    x: deletingCategoryId == category.id ? -50 : 0,
                                    y: showElements ? 0 : 20
                                )
                                .animation(.easeOut(duration: 0.4).delay(0.5 + Double(index) * 0.1), value: showElements)
                                .animation(.easeInOut(duration: 0.4), value: deletingCategoryId)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                                ))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: category.isStarred)
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal)
            }
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .onAppear {
            showElements = false
            withAnimation {
                showElements = true
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditView(
                categoryManager: categoryManager,
                existingCategory: nil,
                isPresented: $showingAddCategory
            )
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditView(
                categoryManager: categoryManager,
                existingCategory: category,
                isPresented: Binding(
                    get: { categoryToEdit != nil },
                    set: { if !$0 { categoryToEdit = nil } }
                )
            )
        }
        .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    // Start the deletion animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deletingCategoryId = category.id
                    }
                    
                    // Delay the actual deletion to allow animation to play
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        categoryManager.deleteCategory(category, dataManager: dataManager)
                        
                        // Reset the animation state
                        withAnimation {
                            deletingCategoryId = nil
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure? Deleting this expense category will delete all expenses under it")
                .foregroundColor(.colPrimaryText)
        }
        .alert("Star Limit Reached", isPresented: $showingStarLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You can only star up to 5 categories. Please unstar a category first.")
                .foregroundColor(.colPrimaryText)
        }
    }
}

// MARK: - Category Row View
struct CategoryRowView: View {
    let category: CustomCategory
    let canDelete: Bool
    let canEdit: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleStar: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Category icon and color
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 32, height: 32)
            
            // Category name
            Text(category.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.colPrimaryText)
            
            Spacer()
            
            // Actions
            HStack(spacing: 10) {
                // Star button (always visible)
                Button(action: onToggleStar) {
                    Image(systemName: category.isStarred ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(category.isStarred ? .yellow : .colSecondaryText)
                }
                
                // Edit button (only for custom categories)
                if canEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundColor(.colAccent)
                    }
                }
                
                // Delete button (only for custom categories)
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagementView(categoryManager: CategoryManager(), dataManager: nil)
            .previewDisplayName("Category Management")
    }
}
#endif