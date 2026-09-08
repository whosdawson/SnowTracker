import SwiftUI

/// Fetches and displays public webcams near a resort, viewable in-app.
struct WebcamGridView: View {
    let resort: Resort

    @State private var webcams: [Webcam] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Finding cameras…")
                    .padding(.top, 60)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await load() }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)
            } else if webcams.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No cameras found near \(resort.name).")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(webcams) { webcam in
                        NavigationLink(value: webcam) {
                            WebcamCardView(webcam: webcam)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(resort.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Webcam.self) { webcam in
            WebcamDetailView(webcam: webcam)
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            webcams = try await WebcamService.shared.fetchWebcams(near: resort)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
