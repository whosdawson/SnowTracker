import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var unitsSettings: UnitsSettings

    var body: some View {
        NavigationStack {
            ResortPickerList(title: "SnowTracker", searchPrompt: "Search any resort or mountain") { resort in
                ResortDetailView(resort: resort)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(unitsSettings.preference == .metric ? "°C" : "°F") {
                        unitsSettings.toggle()
                    }
                }
            }
        }
    }
}
