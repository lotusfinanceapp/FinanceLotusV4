import SwiftUI

// MARK: - Settings View - COMPREHENSIVE APP SETTINGS
struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var showElements = false
    @EnvironmentObject var themeManager: ThemeManager
    
    // Account Management States
    @State private var profileName = "John Doe"
    @State private var profileEmail = "john@example.com"
    @State private var biometricEnabled = false
    @State private var showingPasswordChange = false
    
    // Notifications & Alerts States
    @State private var overspendingAlerts = true
    @State private var billDueDateAlerts = true
    @State private var lowBalanceAlerts = false
    @State private var notificationFrequency = "Immediate"
    @State private var deliveryMethod = "Push"
    
    // Currency & Region States
    @State private var selectedCurrency = "USD"
    @State private var selectedRegion = "United States"
    
    let frequencies = ["Immediate", "Daily", "Weekly"]
    let deliveryMethods = ["Push", "Email", "SMS"]
    let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    let regions = ["United States", "Canada", "United Kingdom", "Australia", "Japan", "Germany"]
    
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
                    
                    // === ACCOUNT MANAGEMENT SECTION ===
                    SettingsSection(
                        title: "Account Management",
                        icon: "person.circle.fill",
                        iconColor: .blue
                    ) {
                        VStack(spacing: 0) {
                            // Edit Profile Info
                            SettingsRow(
                                title: "Edit Profile Info",
                                subtitle: "Update your name and email",
                                icon: "pencil.circle.fill",
                                iconColor: .colAccent,
                                action: {
                                    // Profile editing action
                                }
                            )
                            
                            // Divider
                            Divider()
                                .padding(.leading, 44)
                            
                            // Change Password
                            SettingsRow(
                                title: "Change Password",
                                subtitle: "Update your account password",
                                icon: "key.fill",
                                iconColor: .orange,
                                action: {
                                    showingPasswordChange = true
                                }
                            )
                            
                            // Divider
                            Divider()
                                .padding(.leading, 44)
                            
                            // Biometric Toggle
                            SettingsToggle(
                                title: "Enable Biometric Login",
                                subtitle: "Use Touch ID or Face ID to sign in",
                                icon: "faceid",
                                iconColor: .green,
                                isOn: $biometricEnabled
                            )
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: showElements)
                    
                    // === NOTIFICATIONS & ALERTS SECTION ===
                    SettingsSection(
                        title: "Notifications & Alerts",
                        icon: "bell.circle.fill",
                        iconColor: .green
                    ) {
                        VStack(spacing: 0) {
                            // Toggle Alerts
                            SettingsToggle(
                                title: "Overspending Alerts",
                                subtitle: "Get notified when you exceed your budget",
                                icon: "exclamationmark.triangle.fill",
                                iconColor: .red,
                                isOn: $overspendingAlerts
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsToggle(
                                title: "Bill Due Date Alerts",
                                subtitle: "Reminders for upcoming payments",
                                icon: "calendar.circle.fill",
                                iconColor: .blue,
                                isOn: $billDueDateAlerts
                            )
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            SettingsToggle(
                                title: "Low Balance Alerts",
                                subtitle: "Notifications when balance is low",
                                icon: "creditcard.circle.fill",
                                iconColor: .orange,
                                isOn: $lowBalanceAlerts
                            )
                            
                            // Separator for preference sections
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                                .padding(.vertical, 20)
                            
                            // Notification Frequency
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    
                                    Text("Alert Frequency")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Picker("Frequency", selection: $notificationFrequency) {
                                    ForEach(frequencies, id: \.self) { frequency in
                                        Text(frequency).tag(frequency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.leading, 32)
                            }
                            
                            Divider()
                                .padding(.leading, 44)
                                .padding(.top, 15)
                            
                            // Delivery Method
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "paperplane.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.cyan)
                                        .frame(width: 24)
                                    
                                    Text("Delivery Method")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Picker("Delivery", selection: $deliveryMethod) {
                                    ForEach(deliveryMethods, id: \.self) { method in
                                        Text(method).tag(method)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.leading, 32)
                            }
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showElements)
                    
                    // === APP THEME SECTION ===
                    SettingsSection(
                        title: "App Theme",
                        icon: "paintbrush.fill",
                        iconColor: .orange
                    ) {
                        VStack(spacing: 0) {
                            // Theme Selection
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "palette.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    
                                    Text("Color Theme")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
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
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .padding(.leading, 32)
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showElements)
                    
                    // === CURRENCY & REGION SECTION ===
                    SettingsSection(
                        title: "Currency & Region",
                        icon: "globe.americas.fill",
                        iconColor: .purple
                    ) {
                        VStack(spacing: 0) {
                            // Currency Selection
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    
                                    Text("Preferred Currency")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Menu {
                                    ForEach(currencies, id: \.self) { currency in
                                        Button(action: {
                                            selectedCurrency = currency
                                        }) {
                                            HStack {
                                                Text(currency)
                                                if selectedCurrency == currency {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCurrency)
                                            .foregroundColor(.colPrimaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.colInputBackground)
                                    .cornerRadius(8)
                                }
                                .padding(.leading, 32)
                            }
                            
                            Divider()
                                .padding(.leading, 44)
                                .padding(.vertical, 15)
                            
                            // Region Selection
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text("Region")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                
                                Menu {
                                    ForEach(regions, id: \.self) { region in
                                        Button(action: {
                                            selectedRegion = region
                                        }) {
                                            HStack {
                                                Text(region)
                                                if selectedRegion == region {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedRegion)
                                            .foregroundColor(.colPrimaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.colSecondaryText)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.colInputBackground)
                                    .cornerRadius(8)
                                }
                                .padding(.leading, 32)
                            }
                        }
                    }
                    .opacity(showElements ? 1.0 : 0.0)
                    .offset(y: showElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: showElements)
                    
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
            }
            .onAppear {
                withAnimation {
                    showElements = true
                }
            }
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
        VStack(alignment: .leading, spacing: 15) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 28)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.colPrimaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Section Content
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
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
            .previewDisplayName("Settings Screen")
    }
}
#endif