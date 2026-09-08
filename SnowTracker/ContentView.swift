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
            // Declared once, at the root of the stack, so every push of
            // WebcamGridView/WebcamDetailView (there are two entry points
            // into cameras — the card and the toolbar icon) resolves to the
            // same destination instead of each nested view registering its
            // own (only the one closest to the root would ever be used).
            .navigationDestination(for: WebcamGridRoute.self) { route in
                WebcamGridView(resort: route.resort)
            }
            .navigationDestination(for: Webcam.self) { webcam in
                WebcamDetailView(webcam: webcam)
            }
        }
    }
}
