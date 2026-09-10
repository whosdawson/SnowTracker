import SwiftUI

/// Fetches and displays cameras near a resort from three sources — a curated
/// official webcam page, live YouTube streams, and nearby Windy webcams —
/// shown as separate sections. Any source that's unconfigured or has no
/// coverage for this resort simply doesn't render its section.
struct WebcamGridView: View {
    let resort: Resort

    @State private var officialWebcam: Webcam?
    @State private var liveStreams: [Webcam] = []
    @State private var nearbyWebcams: [Webcam] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadingPhrase = WebcamGridView.loadingPhrases.randomElement()!

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    private static let loadingPhrases = [
        "Scanning the slopes…", "Panning the peaks…", "Tuning in the feeds…",
    ]

    private var hasAnyResults: Bool {
        officialWebcam != nil || !liveStreams.isEmpty || !nearbyWebcams.isEmpty
    }

    var body: some View {
        ScrollView {
            if isLoading && !hasAnyResults {
                ProgressView(loadingPhrase)
                    .padding(.top, 60)
            } else if let errorMessage, !hasAnyResults {
                errorView(errorMessage)
            } else if !hasAnyResults {
                emptyView
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    if let officialWebcam {
                        section(title: "Official Cams", items: [officialWebcam])
                    }
                    if !liveStreams.isEmpty {
                        section(title: "Live Streams", items: liveStreams)
                    }
                    if !nearbyWebcams.isEmpty {
                        section(title: "Nearby Webcams", items: nearbyWebcams)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(AppBackground())
        .navigationTitle(resort.name)
        .navigationBarTitleDisplayMode(.inline)
        // Webcam's navigationDestination is declared once at the stack root
        // (ContentView) rather than here — see the comment there.
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private func section(title: String, items: [Webcam]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { webcam in
                    NavigationLink(value: webcam) {
                        WebcamCardView(webcam: webcam)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "video.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No cameras up here yet")
                .font(.headline)
            Text("Nothing near \(resort.name) right now — check back once the season gets going.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "video.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await load() }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil

        if let urlString = resort.officialWebcamURL, let url = URL(string: urlString) {
            officialWebcam = Webcam(
                id: "official-\(resort.id)",
                title: "\(resort.name) Official Cams",
                previewImageURL: nil,
                detailPageURL: url,
                externalURL: url,
                locationLabel: "Official resort webcam page"
            )
        }

        async let liveResult: [Webcam]? = try? YouTubeService.shared.searchLiveStreams(for: resort)
        async let nearbyResult: [Webcam]? = try? WebcamService.shared.fetchWebcams(near: resort)
        let (live, nearby) = await (liveResult, nearbyResult)
        liveStreams = live ?? []
        nearbyWebcams = nearby ?? []

        if !hasAnyResults && !WebcamAPIConfig.isConfigured && !YouTubeAPIConfig.isConfigured {
            errorMessage = "Add a Windy or YouTube API key in Services/ to enable cameras."
        }

        isLoading = false
    }
}
