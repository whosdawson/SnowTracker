import SwiftUI

/// A subtle night-sky gradient used behind every screen, instead of the
/// plain system background. Echoes the app icon's sunset-alpine palette,
/// muted way down so it reads as atmosphere rather than a wallpaper — the
/// frosted `.thinMaterial` cards throughout the app are what it's for.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.06, blue: 0.13),
                Color(red: 0.10, green: 0.08, blue: 0.20),
                Color(red: 0.07, green: 0.08, blue: 0.16),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
