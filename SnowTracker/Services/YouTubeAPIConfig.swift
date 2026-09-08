import Foundation

/// Live-stream search is powered by the YouTube Data API v3, which requires a
/// free API key. Create one at https://console.cloud.google.com/apis/credentials
/// (enable "YouTube Data API v3" on the project first), then paste it below.
/// Until a key is set, live-stream search is skipped — the other camera
/// sources (official links, nearby Windy webcams) still work.
enum YouTubeAPIConfig {
    static let apiKey = ""

    static var isConfigured: Bool { !apiKey.isEmpty }
}
