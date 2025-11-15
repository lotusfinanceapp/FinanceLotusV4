import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentScreen = 0
    @State private var showContent = false
    @State private var showingCustomNumberPad = false
    @State private var budgetAmount: String = ""
    @State private var budgetSet = false
    @State private var notificationsEnabled = false
    @EnvironmentObject var dataManager: BudgetDataManager
    @EnvironmentObject var notificationManager: NotificationManager

    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.colBackground,
                    Color.colBackground.opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < currentScreen {
                            // Completed
                            Capsule()
                                .fill(Color.colAccent)
                                .frame(height: 4)
                        } else if index == currentScreen {
                            // Current
                            Capsule()
                                .fill(Color.colAccent)
                                .frame(height: 4)
                        } else {
                            // Not completed
                            Capsule()
                                .fill(Color.colSecondaryText.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Screen content
                if currentScreen == 0 {
                    OnboardingScreen1(showContent: $showContent)
                } else if currentScreen == 1 {
                    OnboardingScreen2(showContent: $showContent, dataManager: dataManager)
                } else if currentScreen == 2 {
                    OnboardingScreen3(showContent: $showContent, budgetAmount: $budgetAmount, budgetSet: $budgetSet, showingCustomNumberPad: $showingCustomNumberPad, dataManager: dataManager)
                } else if currentScreen == 3 {
                    OnboardingScreen4(showContent: $showContent, notificationsEnabled: $notificationsEnabled)
                        .environmentObject(notificationManager)
                } else if currentScreen == 4 {
                    OnboardingScreen5(showContent: $showContent, isPresented: $isPresented)
                }

                // Navigation buttons at bottom
                HStack(spacing: 12) {
                    // Back button on screens 1+, nothing on screen 0
                    if currentScreen > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentScreen -= 1
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                                    showContent = true
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.colSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.colCardBackground)
                            .cornerRadius(12)
                        }
                    } else {
                        Spacer()
                    }

                    // Next/Done button
                    Button(action: {
                        if currentScreen < 2 {
                            // Screens 0-1: Allow progression
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentScreen += 1
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                                    showContent = true
                                }
                            }
                        } else if currentScreen == 2 {
                            // Screen 2: Budget screen - only proceed if budget is set
                            if budgetSet {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentScreen += 1
                                    showContent = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                                        showContent = true
                                    }
                                }
                            }
                        } else if currentScreen == 3 {
                            // On notification screen - just move to next screen
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentScreen += 1
                                showContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                                    showContent = true
                                }
                            }
                            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
                        } else if currentScreen == 4 {
                            // On final screen, mark onboarding as completed and dismiss
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            isPresented = false
                        }
                    }) {
                        Text(currentScreen == 4 ? "Get Started" : "Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isNextButtonDisabled() ? .colSecondaryText : .colOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isNextButtonDisabled() ? Color.colSecondaryText.opacity(0.3) : Color.colAccent,
                                        isNextButtonDisabled() ? Color.colSecondaryText.opacity(0.2) : Color.colAccent.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: isNextButtonDisabled() ? Color.clear : Color.colAccent.opacity(0.3), radius: 12, x: 0, y: 8)
                    }
                    .disabled(isNextButtonDisabled())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .opacity(showContent ? 1 : 0)
            }

            // === CUSTOM NUMBER PAD OVERLAY ===
            if showingCustomNumberPad {
                CustomNumberPad(
                    text: $budgetAmount,
                    isPresented: $showingCustomNumberPad,
                    onDismiss: {
                        showingCustomNumberPad = false
                        // Auto-save budget when number pad closes if valid amount
                        if let amount = Double(budgetAmount), amount > 0 {
                            dataManager.setBudget(amount, period: .monthly)
                            budgetSet = true // Mark budget as set
                        }
                    }
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }

    // Helper function to determine if Next button should be disabled
    private func isNextButtonDisabled() -> Bool {
        // Disable on budget screen (2) if budget hasn't been set
        if currentScreen == 2 {
            return !budgetSet
        }
        return false
    }
}

// MARK: - Screen 1: Welcome
struct OnboardingScreen1: View {
    @Binding var showContent: Bool
    @State private var animateIcons = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // App Logo/Branding
                VStack(spacing: 12) {
                    LotusLogo(size: 64, showAnimation: false)

                    Text("Lotus Finance")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.colPrimaryText)

                    Text("Your personal finance companion")
                        .font(.caption)
                        .foregroundColor(.colSecondaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Main illustration/visual
                ZStack {
                    // Decorative circles with animation
                    Circle()
                        .fill(Color.colAccent.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .offset(
                            x: animateIcons ? -12 : 0,
                            y: animateIcons ? -12 : 0
                        )
                        .animation(
                            Animation.easeOut(duration: 0.8)
                                .delay(0.2),
                            value: animateIcons
                        )
                        .modifier(FloatingAnimation(isAnimating: animateIcons))

                    Circle()
                        .fill(Color.colAccent.opacity(0.05))
                        .frame(width: 150, height: 150)
                        .offset(
                            x: animateIcons ? 18 : 0,
                            y: animateIcons ? 14 : 0
                        )
                        .animation(
                            Animation.easeOut(duration: 0.8)
                                .delay(0.3),
                            value: animateIcons
                        )
                        .modifier(FloatingAnimation(isAnimating: animateIcons, delay: 0.5))

                    // Main icon
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            // Wallet icon
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.colAccent)
                                .padding(24)
                                .background(Circle().fill(Color.colAccent.opacity(0.1)))
                                .offset(
                                    x: animateIcons ? -16 : 0,
                                    y: animateIcons ? -12 : 0
                                )
                                .animation(
                                    Animation.easeOut(duration: 0.8)
                                        .delay(0.4),
                                    value: animateIcons
                                )
                                .modifier(FloatingAnimation(isAnimating: animateIcons, delay: 0.2))

                            // Chart icon
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "#10B981"))
                                .padding(24)
                                .background(Circle().fill(Color(hex: "#10B981").opacity(0.1)))
                                .offset(
                                    x: animateIcons ? 16 : 0,
                                    y: animateIcons ? -12 : 0
                                )
                                .animation(
                                    Animation.easeOut(duration: 0.8)
                                        .delay(0.5),
                                    value: animateIcons
                                )
                                .modifier(FloatingAnimation(isAnimating: animateIcons, delay: 0.3))
                        }

                        // Piggy bank icon
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .padding(24)
                            .background(Circle().fill(Color(hex: "#F59E0B").opacity(0.1)))
                            .offset(
                                x: animateIcons ? 0 : 0,
                                y: animateIcons ? 16 : 0
                            )
                            .animation(
                                Animation.easeOut(duration: 0.8)
                                    .delay(0.6),
                                value: animateIcons
                            )
                            .modifier(FloatingAnimation(isAnimating: animateIcons, delay: 0.4))
                    }
                }
                .frame(height: 280)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        animateIcons = true
                    }
                }

                // Subtitle
                Text("Manage your money effortlessly, track expenses, and stay on top of your budget.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.colSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.bottom, 60)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Screen 2: Feature Overview
struct OnboardingScreen2: View {
    @Binding var showContent: Bool
    var dataManager: BudgetDataManager
    @State private var currentFeature: Int = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Logo and Title Section
                VStack(spacing: 12) {
                    LotusLogo(size: 64, showAnimation: false)

                    Text("Lotus Finance")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                }
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Feature card with swipe gesture
                VStack(spacing: 0) {
                    // Card content
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.colBackground.opacity(0.6))
                        .frame(height: 280)
                        .overlay(
                            Group {
                                if currentFeature == 0 {
                                    // Calendar View Demo
                                    VStack(spacing: 0) {
                                        Image("onboarding-calendar")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(hex: "#f5f5f5"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else if currentFeature == 1 {
                                    // Spending Graph Demo
                                    VStack(spacing: 0) {
                                        Image("onboarding-graph")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                } else if currentFeature == 2 {
                                    // Circle Expansion Demo
                                    VStack(spacing: 0) {
                                        Image("onboarding-circle")
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(hex: "#f8f9fb"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == currentFeature ? Color.colAccent : Color.colSecondaryText.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: currentFeature)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 24)

                    // Feature description card
                    VStack(alignment: .leading, spacing: 0) {
                        if currentFeature == 0 {
                            Text("Stay organized with a visual calendar of all your expenses. Recurring payments are highlighted for easy tracking.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.colPrimaryText)
                                .lineSpacing(2)
                        } else if currentFeature == 1 {
                            Text("Analyze your expenses with interactive charts. Daily, weekly, or monthly trends—right at your fingertips.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.colPrimaryText)
                                .lineSpacing(2)
                        } else if currentFeature == 2 {
                            Text("See your budget at a glance. The circle fills as you spend, helping you avoid overspending surprises.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.colPrimaryText)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.colCardBackground)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 0)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width < -threshold && currentFeature < 2 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentFeature += 1
                                }
                            } else if value.translation.width > threshold && currentFeature > 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentFeature -= 1
                                }
                            }
                            dragOffset = 0
                        }
                )

                Spacer()
            }
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.colAccent)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.colPrimaryText)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.colSecondaryText)
                    .lineSpacing(1)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colCardBackground)
        )
    }
}

// MARK: - Floating Animation Modifier
struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let isAnimating: Bool
    var delay: Double = 0.0

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -8 : 8)
            .animation(
                Animation.easeInOut(duration: 2.5)
                    .delay(delay)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if isAnimating {
                        isFloating = true
                    }
                }
            }
            .onChange(of: isAnimating) { newValue in
                if newValue {
                    isFloating = true
                }
            }
    }
}

// MARK: - Preview
#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
            .environmentObject(BudgetDataManager())
    }
}
#endif
