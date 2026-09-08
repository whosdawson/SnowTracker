import SwiftUI

/// Shows a single webcam in-app: a large snapshot plus, when available, the
/// live webcam page rendered in an embedded web view — no need to leave the app.
struct WebcamDetailView: View {
    let webcam: Webcam
    @State private var showLive = false

    var body: some View {
        VStack(spacing: 0) {
            if showLive, let url = webcam.detailPageURL {
                WebView(url: url)
            } else if let url = webcam.previewImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholder
                    default:
                        ProgressView()
                    }
                }
            } else {
                placeholder
            }

            if webcam.detailPageURL != nil {
                Button(showLive ? "Show Snapshot" : "Watch Live In-App") {
                    showLive.toggle()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle(webcam.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholder: some View {
        VStack {
            Image(systemName: "video.slash")
                .font(.largeTitle)
            Text("No image available")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
