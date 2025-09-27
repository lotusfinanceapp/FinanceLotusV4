import SwiftUI

// MARK: - Lotus Logo Component - REUSABLE BRANDING ELEMENT
struct LotusLogo: View {
    let size: CGFloat
    let showAnimation: Bool
    
    @State private var logoScale: Double = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var logoRotation: Double = -10
    
    init(size: CGFloat = 32, showAnimation: Bool = true) {
        self.size = size
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        Image("lotus-logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(showAnimation ? logoScale : 1.0)
            .opacity(showAnimation ? logoOpacity : 1.0)
            .rotationEffect(.degrees(showAnimation ? logoRotation : 0))
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
            .animation(.easeOut(duration: 0.6), value: logoOpacity)
            .animation(.easeOut(duration: 0.7), value: logoRotation)
            .onAppear {
                if showAnimation {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        // Smooth entrance animation with slight rotation for elegance
        withAnimation(.easeOut(duration: 0.5)) {
            logoOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            logoRotation = 0
        }
    }
}

// MARK: - Header with Logo - CONSISTENT TOP BRANDING
struct HeaderWithLogo: View {
    let title: String?
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    @State private var showElements = false
    
    init(title: String? = nil, showBackButton: Bool = false, onBack: (() -> Void)? = nil) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Lotus logo on the left
            LotusLogo(size: 28, showAnimation: true)
                .opacity(showElements ? 1.0 : 0.0)
                .offset(x: showElements ? 0 : -20)
                .animation(.easeOut(duration: 0.6), value: showElements)
            
            // Optional title
            if let title = title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.colPrimaryText)
                    .opacity(showElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: showElements)
            }
            
            Spacer()
            
            // Optional back button
            if showBackButton, let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.colBackButtonIcon)
                }
                .opacity(showElements ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showElements)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .onAppear {
            withAnimation {
                showElements = true
            }
        }
        .onDisappear {
            showElements = false
        }
    }
}

// MARK: - Preview
#if DEBUG
struct LotusLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HeaderWithLogo(title: "Budget Overview")
            HeaderWithLogo(showBackButton: true, onBack: {})
            HeaderWithLogo(title: "Log Expense", showBackButton: true, onBack: {})
            
            Spacer()
        }
        .background(Color.colBackground.ignoresSafeArea(.all))
        .previewDisplayName("Header with Logo Variations")
    }
}
#endif