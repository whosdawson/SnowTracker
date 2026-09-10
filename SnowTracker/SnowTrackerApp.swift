import SwiftUI

@main
struct SnowTrackerApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var unitsSettings = UnitsSettings()
    @StateObject private var dataStore = ResortDataStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
                .environmentObject(unitsSettings)
                .environmentObject(dataStore)
                // The app commits to one dark, atmospheric look (see
                // AppBackground) rather than adapting to system light mode,
                // so the frosted-glass cards render consistently.
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            let currentFavorites = favorites.favorites
            Task {
                await NotificationManager.shared.requestAuthorizationIfNeeded()
                await NotificationManager.shared.checkFavoritesForSnow(currentFavorites)
            }
        }
    }
}
