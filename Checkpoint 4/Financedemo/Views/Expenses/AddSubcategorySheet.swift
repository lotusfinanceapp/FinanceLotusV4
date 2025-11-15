import SwiftUI

// MARK: - Add Subcategory Sheet
struct AddSubcategorySheet: View {
    let category: CustomCategory
    @Binding var subcategoryName: String
    let onAdd: (String) -> Void
    @Binding var isPresented: Bool
    @State private var showElements = false
    @State private var defaultAmount: String = ""
    @State private var showingCustomNumberPad = false

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
                    Image(systemName: category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(category.color)
                        .opacity(showElements ? 1.0 : 0.0)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showElements)

                    Text("Add Subcategory")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.colPrimaryText)

                    Text("Track \(category.name) items with default amounts")
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
                    // Form card
                    VStack(alignment: .leading, spacing: 25) {
                        // Subcategory Name Input
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Subcategory Name")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            TextField("", text: $subcategoryName)
                                .placeholder("e.g., Groceries, Gas", text: $subcategoryName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocorrectionDisabled()
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.words)
                                .font(.body)
                                .foregroundColor(.colInputText)
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

                        // Default Amount Input (Optional)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Default Amount (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.colPrimaryText)

                            Button(action: {
                                hideKeyboard()
                                showingCustomNumberPad = true
                            }) {
                                HStack {
                                    Text(String.currencySymbol())
                                        .foregroundColor(.colSecondaryText)
                                    Text(defaultAmount.isEmpty ? "0.00" : defaultAmount)
                                        .foregroundColor(.colPrimaryText)
                                    Spacer()
                                }
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

                            Text("Auto-fill this amount when selected")
                                .font(.caption)
                                .foregroundColor(.colSecondaryText)
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

                    // Add button at bottom
                    Button(action: {
                        hideKeyboard()
                        onAdd(defaultAmount)
                    }) {
                        Text("Add Subcategory")
                            .font(.headline)
                            .foregroundColor(.colOnAccent)
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
                    .disabled(subcategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(subcategoryName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
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
        .overlay(
            Group {
                if showingCustomNumberPad {
                    CustomNumberPad(
                        text: $defaultAmount,
                        isPresented: $showingCustomNumberPad,
                        onDismiss: {}
                    )
                }
            }
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
