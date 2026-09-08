import Foundation

/// A public webcam near a resort.
struct Webcam: Identifiable, Hashable {
    let id: String
    let title: String
    let previewImageURL: URL?
    let detailPageURL: URL?
    let locationLabel: String?
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
        Webcam(
            id: id.map(String.init) ?? UUID().uuidString,
            title: title ?? "Webcam",
            previewImageURL: (images?.current?.preview ?? images?.current?.thumbnail).flatMap(URL.init(string:)),
            detailPageURL: urls?.detail.flatMap(URL.init(string:)),
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
}
