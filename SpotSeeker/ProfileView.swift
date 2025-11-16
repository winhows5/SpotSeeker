import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.16, blue: 0.20),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)

                Text("Myself")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Empty for now.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}