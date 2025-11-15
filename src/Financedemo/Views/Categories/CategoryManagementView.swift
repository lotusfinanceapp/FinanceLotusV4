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
        NavigationView {
            ZStack {
                Color.colBackground.ignoresSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        // === CATEGORIES LIST ===
                        if categoryManager.allCategories.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 60))
                                    .foregroundColor(.colSecondaryText.opacity(0.5))

                                Text("No Categories")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.colPrimaryText)

                                Text("Add categories to track your expenses")
                                    .font(.subheadline)
                                    .foregroundColor(.colSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxHeight: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(Array(categoryManager.allCategories.enumerated()), id: \.element.id) { index, category in
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
                                    .opacity(deletingCategoryId == category.id ? 0.0 : 1.0)
                                    .scaleEffect(deletingCategoryId == category.id ? 0.8 : 1.0)
                                    .offset(x: deletingCategoryId == category.id ? -50 : 0)
                                    .animation(.easeInOut(duration: 0.4), value: deletingCategoryId)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                        removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                                    ))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: category.isStarred)
                                }

                                // Bottom spacing
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal)
                            .padding(.top, 30)
                        }
                    }
                    .padding(.top, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.colAccent)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        Text("My Categories")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.colPrimaryText)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddCategory = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.colAccent)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Configure navigation bar appearance (MUST be outside NavigationView)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.colBackground)
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance

            showElements = false
            print("📊 CategoryManagementView - Total categories: \(categoryManager.allCategories.count)")
            print("📊 Default categories: \(categoryManager.defaultCategories.count)")
            print("📊 Custom categories: \(categoryManager.customCategories.count)")
            for category in categoryManager.allCategories {
                print("   - \(category.name)")
            }
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