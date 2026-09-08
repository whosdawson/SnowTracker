import SwiftUI

struct CamerasTabView: View {
    var body: some View {
        NavigationStack {
            ResortPickerList(title: "Cameras", searchPrompt: "Search any resort or mountain") { resort in
                WebcamGridView(resort: resort)
            }
        }
    }
}
