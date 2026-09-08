import SwiftUI

/// Shows a single webcam in-app: a large snapshot plus, when available, the
/// live webcam page rendered in an embedded web view — no need to leave the app.
struct WebcamDetailView: View {
    let webcam: Webcam
    @State private var showLive: Bool

    /// Entries with no snapshot (e.g. an official webcam page link) go
    /// straight to the live view — there's nothing else to show first.
    init(webcam: Webcam) {
        self.webcam = webcam
        _showLive = State(initialValue: webcam.previewImageURL == nil && webcam.detailPageURL != nil)
    }

    private var canToggle: Bool {
        webcam.previewImageURL != nil && webcam.detailPageURL != nil
    }

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

            if canToggle {
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
