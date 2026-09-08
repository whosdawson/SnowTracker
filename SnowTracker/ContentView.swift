import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ForecastTabView()
                .tabItem {
                    Label("Forecast", systemImage: "snowflake")
                }

            CamerasTabView()
                .tabItem {
                    Label("Cameras", systemImage: "video")
                }
        }
    }
}
