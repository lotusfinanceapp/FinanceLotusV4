import SwiftUI

// MARK: - Reusable Logo Component
struct LogoComponent: View {
    let size: CGFloat
    let opacity: Double
    
    init(size: CGFloat = 60, opacity: Double = 1.0) {
        self.size = size
        self.opacity = opacity
    }
    
    var body: some View {
        Image("lotus-logo-no-bg")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(opacity)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#if DEBUG
struct LogoComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LogoComponent(size: 40)
            LogoComponent(size: 60)
            LogoComponent(size: 80)
        }
        .padding()
        .previewDisplayName("Logo Sizes")
    }
}
#endif