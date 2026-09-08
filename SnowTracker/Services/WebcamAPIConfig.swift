import Foundation

/// Webcams are provided by the Windy Webcams API, which requires a free API key.
/// Sign up at https://api.windy.com/webcams/dev to get one, then paste it below.
/// Until a key is set, the Cameras tab shows a friendly "not configured" message
/// instead of making requests.
enum WebcamAPIConfig {
    static let apiKey = ""

    static var isConfigured: Bool { !apiKey.isEmpty }
}
