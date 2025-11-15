import SwiftUI

// MARK: - Screen 4: Enable Notifications (Onboarding Only)
struct OnboardingScreen4: View {
    @Binding var showContent: Bool
    @Binding var notificationsEnabled: Bool
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var animateElements = false
    @State private var permissionRequestPending = false
    @State private var showSettingsAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // === HEADER WITH ANIMATED ICON ===
                ZStack {
                    VStack(spacing: 20) {
                        // Large bell icon with subtle animation
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Color(hex: "#10B981"))
                            .padding(24)
                            .background(
                                Circle()
                                    .fill(Color(hex: "#10B981").opacity(0.12))
                            )
                            .modifier(FloatingAnimation(isAnimating: animateElements, delay: 0.1))
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        // Main text
                        VStack(spacing: 12) {
                            Text("Stay Updated")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.colPrimaryText)
                                .multilineTextAlignment(.center)

                            Text("Get notified about your transactions")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.colSecondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 280)
                .padding(.bottom, 40)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)

                // === NOTIFICATION BENEFITS CARDS ===
                VStack(spacing: 16) {
                    // Benefit 1: Real-time alerts
                    NotificationBenefitCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Color(hex: "#10B981"),
                        title: "Real-time Alerts",
                        description: "Get instant confirmations when you add expenses"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: showContent)

                    // Benefit 2: Budget reminders
                    NotificationBenefitCard(
                        icon: "bell.circle.fill",
                        iconColor: Color(hex: "#F59E0B"),
                        title: "Budget Reminders",
                        description: "Stay on track with recurring expense alerts"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

                    // Benefit 3: Never miss updates
                    NotificationBenefitCard(
                        icon: "envelope.circle.fill",
                        iconColor: Color(hex: "#3B82F6"),
                        title: "Never Miss Updates",
                        description: "Important financial insights delivered to you"
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                // === ENABLE NOTIFICATIONS TOGGLE ===
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#10B981"))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Notifications")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.colPrimaryText)

                            Text("Get alerts for expenses and reminders")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.colSecondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { newValue in
                                print("🔔 OnboardingScreen4: Toggle changed to \(newValue)")
                                if newValue {
                                    print("🔔 OnboardingScreen4: Checking if iOS notifications are authorized")
                                    print("🔔 OnboardingScreen4: notificationManager.isAuthorized = \(notificationManager.isAuthorized)")
                                    if notificationManager.isAuthorized {
                                        // iOS notifications already allowed
                                        print("🔔 OnboardingScreen4: Already authorized, no action needed")
                                    } else {
                                        // Check if notifications were previously denied
                                        let wasEverDenied = UserDefaults.standard.bool(forKey: "notificationPermissionDenied")
                                        print("🔔 OnboardingScreen4: wasEverDenied = \(wasEverDenied)")

                                        if wasEverDenied {
                                            // User denied before, show settings alert
                                            print("🔔 OnboardingScreen4: User denied notifications before - showing settings alert")
                                            notificationsEnabled = false
                                            showSettingsAlert = true
                                        } else {
                                            // First time requesting
                                            print("🔔 OnboardingScreen4: First time requesting notification permission")
                                            permissionRequestPending = true
                                            notificationManager.requestPermission()
                                        }
                                    }
                                }
                            }
                            .scaleEffect(0.95)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.colInputBackground)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.colCardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: showContent)

                // === PRIVACY NOTE ===
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.colAccent)

                        Text("We respect your privacy. You can change notification settings anytime.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.colSecondaryText)
                            .lineSpacing(1)

                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.colAccent.opacity(0.08))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            // Trigger floating animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateElements = true
            }

            // Check current authorization status
            print("🔔 OnboardingScreen4: onAppear - checking current auth status")
            notificationManager.checkAuthorizationStatusAndUpdate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check authorization status when app returns from settings
            print("🔔 OnboardingScreen4: App returned to foreground - checking auth status")
            notificationManager.checkAuthorizationStatusAndUpdate()
        }
        .onReceive(notificationManager.$isAuthorized) { newAuthStatus in
            // Handle authorization status changes
            print("🔔 OnboardingScreen4: isAuthorized changed to \(newAuthStatus)")
            print("🔔 OnboardingScreen4: notificationsEnabled is \(notificationsEnabled)")
            print("🔔 OnboardingScreen4: permissionRequestPending is \(permissionRequestPending)")

            // Case 1: User just denied permission
            if permissionRequestPending && !newAuthStatus && notificationsEnabled {
                print("🔔 OnboardingScreen4: User denied permission - toggling OFF and marking flag")
                // Mark that user has denied notifications so we show settings alert next time
                UserDefaults.standard.set(true, forKey: "notificationPermissionDenied")
                withAnimation(.easeInOut(duration: 0.3)) {
                    notificationsEnabled = false
                }
            }

            // Case 2: User enabled notifications in settings (detected on app return)
            if newAuthStatus && UserDefaults.standard.bool(forKey: "notificationPermissionDenied") {
                print("🔔 OnboardingScreen4: User enabled notifications in settings - clearing denied flag")
                UserDefaults.standard.set(false, forKey: "notificationPermissionDenied")
            }

            permissionRequestPending = false
        }
        .alert("Enable Notifications in iOS Settings", isPresented: $showSettingsAlert) {
            Button("Open Settings", action: {
                // Open the app's notification settings directly
                if let url = URL(string: UIApplication.openSettingsURLString + "com.apple.Preferences.Notifications.Settings") {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    // Fallback to general app settings if specific notification URL doesn't work
                    UIApplication.shared.open(url)
                }
            })
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enable notifications, please go to iOS Settings > Notifications and allow this app to send notifications.")
        }
    }
}

// MARK: - Notification Benefit Card Component
struct NotificationBenefitCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.colPrimaryText)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.colSecondaryText)
                    .lineSpacing(0.5)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.colCardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct OnboardingScreen4_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen4(showContent: .constant(true), notificationsEnabled: .constant(false))
            .environmentObject(NotificationManager())
            .previewDisplayName("Onboarding Screen 4 - Notifications")
    }
}
#endif
