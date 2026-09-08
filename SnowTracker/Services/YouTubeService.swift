import Foundation

enum YouTubeServiceError: LocalizedError {
    case missingAPIKey
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a free YouTube Data API key in YouTubeAPIConfig.swift to enable live streams."
        case .requestFailed:
            return "Couldn't search live streams. Check your connection and try again."
        }
    }
}

/// Finds a resort's official live-cam YouTube streams, if any are currently
/// live, via the YouTube Data API v3. Results are reused as `Webcam` values
/// (same shape as Windy webcams) so they share the existing card/detail UI —
/// `detailPageURL` points at YouTube's normal watch page (not the /embed/
/// iframe player), which plays inline in the in-app web view for any live
/// stream regardless of whether the channel has third-party embedding
/// disabled — that restriction only applies to the constrained iframe embed
/// API, not to loading youtube.com itself.
struct YouTubeService {
    static let shared = YouTubeService()

    private let searchURL = "https://www.googleapis.com/youtube/v3/search"

    func searchLiveStreams(for resort: Resort, maxResults: Int = 6) async throws -> [Webcam] {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeServiceError.missingAPIKey
        }

        var components = URLComponents(string: searchURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "eventType", value: "live"),
            URLQueryItem(name: "q", value: "\(resort.name) ski resort live webcam"),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw YouTubeServiceError.requestFailed
            }
            data = responseData
        } catch let error as YouTubeServiceError {
            throw error
        } catch {
            throw YouTubeServiceError.requestFailed
        }

        let decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        return (decoded.items ?? []).compactMap { $0.asWebcam }
    }
}

private struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]?
}

private struct YouTubeSearchItem: Decodable {
    let id: YouTubeVideoID?
    let snippet: YouTubeSnippet?

    var asWebcam: Webcam? {
        guard let videoId = id?.videoId else { return nil }
        let watchURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")
        return Webcam(
            id: "yt-\(videoId)",
            title: snippet?.title ?? "Live Stream",
            previewImageURL: snippet?.thumbnails?.medium?.url.flatMap(URL.init(string:)),
            detailPageURL: watchURL,
            externalURL: watchURL,
            locationLabel: snippet?.channelTitle
        )
    }
}

private struct YouTubeVideoID: Decodable {
    let videoId: String?
}

private struct YouTubeSnippet: Decodable {
    let title: String?
    let channelTitle: String?
    let thumbnails: YouTubeThumbnails?
}

private struct YouTubeThumbnails: Decodable {
    let medium: YouTubeThumbnail?
}

private struct YouTubeThumbnail: Decodable {
    let url: String?
}
