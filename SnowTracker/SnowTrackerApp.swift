import SwiftUI

@main
struct SnowTrackerApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var unitsSettings = UnitsSettings()
    @StateObject private var dataStore = ResortDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
                .environmentObject(unitsSettings)
                .environmentObject(dataStore)
        }
    }
}
