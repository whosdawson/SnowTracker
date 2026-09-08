import SwiftUI

/// Shows a single webcam in-app: the live page/stream in an embedded web
/// view whenever one's available, otherwise a static snapshot.
struct WebcamDetailView: View {
    let webcam: Webcam

    var body: some View {
        Group {
            if let url = webcam.detailPageURL {
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
        }
        .navigationTitle(webcam.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let externalURL = webcam.externalURL {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Escape hatch: some pages just won't load correctly
                    // embedded but work fine opened directly.
                    Link(destination: externalURL) {
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
            }
        }
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
