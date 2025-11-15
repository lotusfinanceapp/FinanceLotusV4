import SwiftUI

// MARK: - Settings View - COMPREHENSIVE APP SETTINGS
struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var showElements = false
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var dataManager: BudgetDataManager

    // Budget & Notifications States
    @State private var showingBudgetEdit = false

    // Notifications & Alerts States
    @State private var overspendingAlerts = true
    @State private var showingNotificationAlert = false

    // Onboarding State
    @State private var showingTestOnboarding = false

    // Currency State
    @State private var selectedCurrency = "USD"

    let currencies = ["USD", "EUR", "CNY", "JPY", "GBP", "CAD"]

    // MARK: - Initialization
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        _selectedCurrency = State(initialValue: UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD")
        _overspendingAlerts = State(initialValue: UserDefaults.standard.bool(forKey: "notificationsEnabled"))
        // Default to true if key doesn't exist (first time)
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains("notificationsEnabled") {
            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // === BACKGROUND LAYER ===
                Color.colBackground
                    .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // === TOP SPACING ===
                        Color.clear.frame(height: 20)
                    
                    // === BUDGET MANAGEMENT SECTION ===
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.colPrimaryText)

                        Button(action: {
                            showingBudgetEdit = true
                        }) {
                            HStack(spacing: 15) {
                                Circle()
                                    .fill(Color.colAccent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "banknote")
                                            .font(.system(size: 20))
                                            .foregroundColor(.colAccent)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monthly Budget")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.colPrimaryText)

                                    if let budget = dataManager.budget {
                                        Text(budget.amount.formattedCurrency())
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    } else {
                                        Text("Not set")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.colSecondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.colCardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showElements)

                    // === NOTIFICATIONS SECTION ===
                    SettingsSection(
                        title: "Notifications",
                        icon: "bell.circle.fill",
                        iconColor: .green
                    ) {
                        VStack(spacing: 0) {
                            SettingsToggle(
                                title: "Enable Notifications",
                                subtitle: "",
                                icon: "bell.fill",
                                iconColor: .green,
                                isOn: $overspendingAlerts
                            )
                            .onChange(of: overspendingAlerts) { newValue in
                                // If user is trying to enable notifications, check if iOS allows it
                                if newValue && !notificationManager.isAuthorized {
                                    // iOS notifications are disabled, show alert
                                    overspendingAlerts = false // Revert toggle
                                    showingNotificationAlert = true
                                } else if !newValue {
                                    // User is disabling - always save
                                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                                } else {
                                    // User is enabling and iOS allows it - save
                                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                                }
                            }
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: showElements)

                    // === APP THEME SECTION ===
                    SettingsSection(
                        title: "App Theme",
                        icon: "paintbrush.fill",
                        iconColor: .orange
                    ) {
                        VStack(spacing: 0) {
                            // Theme Selection
                            VStack(alignment: .leading, spacing: 15) {
                                // Theme options
                                ForEach(ThemeManager.AppTheme.allCases) { theme in
                                    Button(action: {
                                        themeManager.setTheme(theme)
                                    }) {
                                        HStack(spacing: 16) {
                                            // Theme preview colors
                                            HStack(spacing: 4) {
                                                ForEach(0..<3, id: \.self) { index in
                                                    Circle()
                                                        .fill(theme.previewColors[index])
                                                        .frame(width: 16, height: 16)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(theme.displayName)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.colPrimaryText)
                                                
                                                Text(theme.description)
                                                    .font(.caption)
                                                    .foregroundColor(.colSecondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            if themeManager.currentTheme == theme {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.colAccent)
                                                    .font(.title3)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(themeManager.currentTheme == theme ? Color.colAccent.opacity(0.1) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if theme != ThemeManager.AppTheme.allCases.last {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: showElements)

                    // === CURRENCY SECTION ===
                    SettingsSection(
                        title: "Currency",
                        icon: "dollarsign.circle.fill",
                        iconColor: .green
                    ) {
                        VStack(spacing: 0) {
                            Menu {
                                ForEach(currencies, id: \.self) { currency in
                                    Button(action: {
                                        selectedCurrency = currency
                                        UserDefaults.standard.set(currency, forKey: "selectedCurrency")
                                    }) {
                                        HStack {
                                            Image(systemName: currencyIconForCode(currency))
                                                .font(.system(size: 16))
                                            Text(currency)
                                            if selectedCurrency == currency {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 15) {
                                    Circle()
                                        .fill(Color.colAccent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: currencyIconForCode(selectedCurrency))
                                                .font(.system(size: 20))
                                                .foregroundColor(.colAccent)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Preferred Currency")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.colPrimaryText)

                                        Text(selectedCurrency)
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.colSecondaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: showElements)

                    // === TEST ONBOARDING SECTION ===
                    SettingsSection(
                        title: "Test",
                        icon: "questionmark.circle.fill",
                        iconColor: .orange
                    ) {
                        VStack(spacing: 0) {
                            Button(action: {
                                showingTestOnboarding = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("View Onboarding")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.colPrimaryText)

                                        Text("See the welcome tutorial")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.colSecondaryText)
                                }
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.55), value: showElements)

                    // === BOTTOM SPACING ===
                    Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Settings")
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

                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.colPrimaryText)
                }
            }
            .onAppear {
                withAnimation {
                    showElements = true
                }
                // Check authorization status when view appears (in case user changed iOS settings)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    notificationManager.checkAuthorizationStatusAndUpdate()
                }
            }
            .fullScreenCover(isPresented: $showingBudgetEdit) {
                SetBudgetView(dataManager: dataManager)
            }
            .fullScreenCover(isPresented: $showingTestOnboarding) {
                OnboardingView(isPresented: $showingTestOnboarding)
            }
            .alert("Enable Notifications in iOS Settings", isPresented: $showingNotificationAlert) {
                Button("Open Settings", action: {
                    // Close the settings view first
                    isPresented = false

                    // Then open iOS Notification Settings
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Open the app's notification settings directly
                        if let url = URL(string: UIApplication.openSettingsURLString + "com.apple.Preferences.Notifications.Settings") {
                            UIApplication.shared.open(url)
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            // Fallback to general app settings if specific notification URL doesn't work
                            UIApplication.shared.open(url)
                        }
                    }
                })
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To enable notifications, please go to iOS Settings > Notifications and allow this app to send notifications.")
            }
        }
    }

    // MARK: - Helper Functions
    private func currencyIconForCode(_ code: String) -> String {
        switch code {
        case "USD":
            return "dollarsign"
        case "EUR":
            return "eurosign"
        case "GBP":
            return "sterlingsign"
        case "CAD":
            return "dollarsign"
        case "JPY":
            return "yensign"
        case "CNY":
            return "yensign"
        default:
            return "dollarsign"
        }
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.colPrimaryText)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.colCardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.colPrimaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.colSecondaryText)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Toggle Component
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.colPrimaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.colSecondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .scaleEffect(0.85)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isPresented: .constant(true))
            .environmentObject(ThemeManager())
            .environmentObject(NotificationManager())
            .previewDisplayName("Settings Screen")
    }
}
#endif
