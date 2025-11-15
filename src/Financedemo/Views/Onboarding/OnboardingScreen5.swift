import SwiftUI

// MARK: - Screen 5: You're All Set (Completion)
struct OnboardingScreen5: View {
    @Binding var showContent: Bool
    @Binding var isPresented: Bool
    @State private var animateCheckmark = false
    @State private var animateElements = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // === ANIMATED CHECKMARK CIRCLE ===
                ZStack {
                    // Outer ring with animation
                    Circle()
                        .stroke(Color.colAccent.opacity(0.2), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.8)
                        .opacity(animateCheckmark ? 0.3 : 0.0)
                        .animation(
                            Animation.easeOut(duration: 0.6)
                                .delay(0.3),
                            value: animateCheckmark
                        )

                    // Middle ring
                    Circle()
                        .stroke(Color.colAccent.opacity(0.4), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.7)
                        .opacity(animateCheckmark ? 0.5 : 0.0)
                        .animation(
                            Animation.easeOut(duration: 0.6)
                                .delay(0.2),
                            value: animateCheckmark
                        )

                    // Checkmark icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding(32)
                        .background(
                            Circle()
                                .fill(Color.colAccent)
                        )
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        .opacity(animateCheckmark ? 1.0 : 0.0)
                        .animation(
                            Animation.spring(response: 0.6, dampingFraction: 0.7)
                                .delay(0.3),
                            value: animateCheckmark
                        )
                }
                .frame(height: 200)
                .padding(.bottom, 40)

                // === MAIN TEXT ===
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.colPrimaryText)
                        .multilineTextAlignment(.center)

                    Text("Your budget is ready and you're set up to track every dollar")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.colSecondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)

                // === QUICK TIPS ===
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Tips to Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.colPrimaryText)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    VStack(spacing: 12) {
                        TipRow(
                            number: "1",
                            title: "Add Your First Expense",
                            description: "Start tracking by logging your daily purchases"
                        )

                        TipRow(
                            number: "2",
                            title: "Check Your Progress",
                            description: "View your budget circle to see how much you can spend"
                        )

                        TipRow(
                            number: "3",
                            title: "Review Your Analytics",
                            description: "Get insights with charts and spending breakdowns"
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.colCardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
                animateCheckmark = true
            }
        }
    }
}

// MARK: - Tip Row Component
struct TipRow: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.colAccent,
                            Color.colAccent.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text(number)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.colPrimaryText)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.colSecondaryText)
                    .lineSpacing(0.5)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.colInputBackground)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct OnboardingScreen5_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen5(showContent: .constant(true), isPresented: .constant(true))
            .previewDisplayName("Onboarding Screen 5 - You're All Set")
    }
}
#endif
