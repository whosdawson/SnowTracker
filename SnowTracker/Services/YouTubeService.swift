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
/// `detailPageURL` points at the YouTube embed player, which plays inline in
/// the in-app web view.
struct YouTubeService {
    static let shared = YouTubeService()

    private let searchURL = "https://www.googleapis.com/youtube/v3/search"
    private let videosURL = "https://www.googleapis.com/youtube/v3/videos"

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
        let candidates = decoded.items ?? []
        let videoIds = candidates.compactMap { $0.id?.videoId }

        // Many official/brand channels disable embedding for their live
        // streams, which shows as a "video player configuration error" in
        // an embedded web view even though the stream itself is fine. Drop
        // those before they ever reach the UI. If this check itself fails
        // (network hiccup), fail open and show the unfiltered candidates
        // rather than losing all results over it.
        if let embeddableIds = try? await fetchEmbeddableVideoIds(videoIds) {
            return candidates
                .filter { embeddableIds.contains($0.id?.videoId ?? "") }
                .compactMap { $0.asWebcam }
        }
        return candidates.compactMap { $0.asWebcam }
    }

    private func fetchEmbeddableVideoIds(_ ids: [String]) async throws -> Set<String> {
        guard !ids.isEmpty else { return [] }

        var components = URLComponents(string: videosURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "status"),
            URLQueryItem(name: "id", value: ids.joined(separator: ",")),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw YouTubeServiceError.requestFailed
        }

        let decoded = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
        let embeddable = (decoded.items ?? [])
            .filter { $0.status?.embeddable == true }
            .compactMap { $0.id }
        return Set(embeddable)
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
        return Webcam(
            id: "yt-\(videoId)",
            title: snippet?.title ?? "Live Stream",
            previewImageURL: snippet?.thumbnails?.medium?.url.flatMap(URL.init(string:)),
            detailPageURL: URL(string: "https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1"),
            externalURL: URL(string: "https://www.youtube.com/watch?v=\(videoId)"),
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

private struct YouTubeVideosResponse: Decodable {
    let items: [YouTubeVideoStatusItem]?
}

private struct YouTubeVideoStatusItem: Decodable {
    let id: String?
    let status: YouTubeVideoStatus?
}

private struct YouTubeVideoStatus: Decodable {
    let embeddable: Bool?
}
