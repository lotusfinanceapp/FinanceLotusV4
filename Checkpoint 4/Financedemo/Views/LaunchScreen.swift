import SwiftUI

// MARK: - Launch Screen - MODERN LOTUS EXPERIENCE
struct LaunchScreen: View {
    @State private var logoScale: Double = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var logoRotation: Double = -15
    @State private var showGlow: Bool = false
    @State private var showAppName: Bool = false
    @State private var showTagline: Bool = false
    @State private var backgroundOpacity: Double = 0.0
    @State private var pulseScale: Double = 1.0
    @State private var isAnimationComplete: Bool = false

    let onLaunchComplete: () -> Void

    var body: some View {
        ZStack {
            // Modern gradient background with animated opacity
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.colAccent.opacity(0.1),
                    Color.colBackground,
                    Color.black.opacity(0.1)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .ignoresSafeArea(.all)
            .opacity(backgroundOpacity)
            .animation(.easeInOut(duration: 1.2), value: backgroundOpacity)

            // Animated particles/dots in background
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.colAccent.opacity(0.3))
                    .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...700)
                    )
                    .scaleEffect(pulseScale)
                    .opacity(showGlow ? 0.6 : 0.0)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: pulseScale
                    )
            }

            VStack(spacing: 40) {
                Spacer()

                ZStack {
                    // Glow effect behind logo
                    if showGlow {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.colAccent.opacity(0.4),
                                        Color.colAccent.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                    }

                    // Main lotus logo with modern animations
                    Image("lotus-logo-no-bg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(logoRotation))
                        .shadow(color: Color.colAccent.opacity(0.3), radius: 20, x: 0, y: 10)
                }

                // App branding with modern typography
                VStack(spacing: 16) {
                    if showAppName {
                        Text("Lotus Finance")
                            .font(.system(size: 32, weight: .ultraLight, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.colPrimaryText,
                                        Color.colAccent.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(showAppName ? 1.0 : 0.0)
                            .offset(y: showAppName ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: showAppName)
                    }

                    if showTagline {
                        Text("Mindful • Modern • Money")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.colSecondaryText)
                            .tracking(2)
                            .opacity(showTagline ? 0.8 : 0.0)
                            .offset(y: showTagline ? 0 : 15)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: showTagline)
                    }
                }

                Spacer()

                // Modern loading indicator
                if showGlow {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.colAccent.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: pulseScale
                                )
                        }
                    }
                    .opacity(showGlow ? 0.8 : 0.0)
                    .animation(.easeInOut(duration: 0.4).delay(1.0), value: showGlow)
                }

                Spacer()
            }
        }
        .onAppear {
            startModernLaunchAnimation()
        }
    }
    
    private func startModernLaunchAnimation() {
        // Phase 1: Animate background and particles
        withAnimation(.easeInOut(duration: 1.0)) {
            backgroundOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                pulseScale = 1.2
            }
        }

        // Phase 2: Dramatic logo entrance with rotation and scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1.0
            }

            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoRotation = 0
            }
        }

        // Phase 3: Activate glow effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showGlow = true
            }
        }

        // Phase 4: Show app name with spring animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showAppName = true
            }
        }

        // Phase 5: Show tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showTagline = true
            }
        }

        // Phase 6: Complete launch after extended animation time
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            isAnimationComplete = true
            onLaunchComplete()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen(onLaunchComplete: {})
            .previewDisplayName("Launch Screen")
    }
}
#endif