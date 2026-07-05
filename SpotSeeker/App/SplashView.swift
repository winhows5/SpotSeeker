import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            SplashBackgroundView()

            VStack(spacing: 16) {
                Text("Baxi")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .kerning(1.2)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .scaleEffect(animate ? 1.0 : 0.98)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3), value: animate)

                // Decorative separator
                Rectangle()
                    .fill(.white.opacity(0.75))
                    .frame(width: 120, height: 2)
                    .cornerRadius(1)

                Text("For Every Precious Moment in Life.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animate)
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

struct SplashBackgroundView: View {
    var body: some View {
        ZStack {
            // Prefer an asset named "IMG_8556" (add img/IMG_8556.jpeg to Assets.xcassets)
            if let img = UIImage(named: "IMG_8556") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    // Dim the image to keep text readable
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.55),
                                Color.black.opacity(0.25)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .blur(radius: 2)
                    .ignoresSafeArea()
            } else {
                // Fallback modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.16),
                        Color(red: 0.06, green: 0.06, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            // Subtle decorative shapes
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: -120, y: -180)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 180, height: 180)
                .blur(radius: 24)
                .offset(x: 160, y: 140)
        }
    }
}