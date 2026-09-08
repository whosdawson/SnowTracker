import Foundation

/// A public webcam near a resort.
struct Webcam: Identifiable, Hashable {
    let id: String
    let title: String
    let previewImageURL: URL?
    /// Loaded in the embedded in-app web view when the user taps "Watch Live".
    let detailPageURL: URL?
    /// Opened in the system browser/app as a fallback — e.g. for a YouTube
    /// live stream, this is the normal watch page rather than the /embed/
    /// URL, so it still works if the embed itself is blocked or errors
    /// (some channels disable embedding, which shows as a player error
    /// in-app but plays fine in the YouTube app or Safari).
    let externalURL: URL?
    let locationLabel: String?
}

/// Navigation value for "show the camera grid for this resort". A distinct
/// type (rather than reusing `Resort`) so it can have its own
/// `navigationDestination`, separate from Resort's (which goes to
/// ResortDetailView).
struct WebcamGridRoute: Hashable {
    let resort: Resort
}

// MARK: - Windy Webcams API v3 response (decoding layer)
// Docs: https://api.windy.com/webcams/docs

struct WindyWebcamsResponse: Decodable {
    let webcams: [WindyWebcam]?
}

struct WindyWebcam: Decodable {
    let id: Int?
    let title: String?
    let images: WindyImages?
    let urls: WindyURLs?
    let location: WindyLocation?

    var asWebcam: Webcam {
        let detailURL = urls?.detail.flatMap(URL.init(string:))
        return Webcam(
            id: id.map(String.init) ?? UUID().uuidString,
            title: title ?? "Webcam",
            previewImageURL: (images?.current?.preview ?? images?.current?.thumbnail).flatMap(URL.init(string:)),
            detailPageURL: detailURL,
            externalURL: detailURL,
            locationLabel: [location?.city, location?.region].compactMap { $0 }.joined(separator: ", ")
        )
    }
}

struct WindyImages: Decodable {
    let current: WindyImageSet?
}

struct WindyImageSet: Decodable {
    let preview: String?
    let thumbnail: String?
}

struct WindyURLs: Decodable {
    let detail: String?
}

struct WindyLocation: Decodable {
    let city: String?
    let region: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
}
