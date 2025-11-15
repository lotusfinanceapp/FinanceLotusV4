import SwiftUI

// MARK: - Amount Filter Sheet
struct AmountFilterView: View {
    @Binding var minAmount: String
    @Binding var maxAmount: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Filter by Amount")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)

                    Text("Set min and max amounts")
                        .font(.body)
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.top, 40)

                VStack(spacing: 20) {
                    // Minimum amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Amount")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.colPrimaryText)

                        HStack {
                            Text(String.currencySymbol())
                                .font(.title3)
                                .foregroundColor(.colSecondaryText)

                            TextField("", text: $minAmount)
                                .placeholder("0", text: $minAmount)
                                .font(.title3)
                                .foregroundColor(.colInputText)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }

                    // Maximum amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Amount")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.colPrimaryText)

                        HStack {
                            Text(String.currencySymbol())
                                .font(.title3)
                                .foregroundColor(.colSecondaryText)

                            TextField("", text: $maxAmount)
                                .placeholder("1000", text: $maxAmount)
                                .font(.title3)
                                .foregroundColor(.colInputText)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.colCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }

                    // Clear filter button
                    Button(action: {
                        hideKeyboard()
                        minAmount = ""
                        maxAmount = ""
                    }) {
                        Text("Clear Amount Filter")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.colAccent)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.colAccent.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.colBackground.ignoresSafeArea())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.colBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hideKeyboard()
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
                    Text("Amount Filter")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
