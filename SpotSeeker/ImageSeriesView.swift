import SwiftUI

struct ImageSeriesView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.16),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)

                Text("ImageSeries")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Empty for now.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}