import Foundation
import CoreLocation

enum WebcamServiceError: LocalizedError {
    case missingAPIKey
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a free Windy Webcams API key in WebcamAPIConfig.swift to enable cameras."
        case .requestFailed:
            return "Couldn't load cameras. Check your connection and try again."
        }
    }
}

/// Fetches public webcams near a resort from the Windy Webcams API.
struct WebcamService {
    static let shared = WebcamService()

    private let baseURL = "https://api.windy.com/webcams/api/v3/webcams"

    /// - Parameters:
    ///   - radiusKm: how far from the resort to search.
    ///   - limit: how many webcams to return, closest first.
    func fetchWebcams(near resort: Resort, radiusKm: Int = 25, limit: Int = 12) async throws -> [Webcam] {
        guard WebcamAPIConfig.isConfigured else {
            throw WebcamServiceError.missingAPIKey
        }

        // v3's location filter is a single combined value: "lat,lon,radiusKm"
        // (not separate `near`/`radius` params — those are silently ignored).
        // We also over-fetch a wider candidate pool (capped at Windy's max of 50)
        // and sort it ourselves by real distance from the resort below, since
        // Windy's own ordering isn't guaranteed to be distance-based and can
        // surface a busier nearby town's webcams ahead of the resort's own.
        let requestLimit = min(max(limit * 3, 24), 50)

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "nearby", value: "\(resort.latitude),\(resort.longitude),\(radiusKm)"),
            URLQueryItem(name: "limit", value: "\(requestLimit)"),
            URLQueryItem(name: "include", value: "images,location,urls"),
            URLQueryItem(name: "lang", value: "en"),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(WebcamAPIConfig.apiKey, forHTTPHeaderField: "X-WINDY-API-KEY")

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw WebcamServiceError.requestFailed
            }
            data = responseData
        } catch let error as WebcamServiceError {
            throw error
        } catch {
            throw WebcamServiceError.requestFailed
        }

        let decoded = try JSONDecoder().decode(WindyWebcamsResponse.self, from: data)
        let resortLocation = CLLocation(latitude: resort.latitude, longitude: resort.longitude)

        let sorted = (decoded.webcams ?? []).sorted {
            Self.distanceKm(from: resortLocation, to: $0.location) < Self.distanceKm(from: resortLocation, to: $1.location)
        }

        return sorted.prefix(limit).map { $0.asWebcam }
    }

    /// Distance in km from the resort to a webcam. Webcams missing coordinates
    /// sort last rather than being dropped, since they may still be relevant.
    private static func distanceKm(from resortLocation: CLLocation, to location: WindyLocation?) -> Double {
        guard let lat = location?.latitude, let lon = location?.longitude else {
            return .greatestFiniteMagnitude
        }
        return resortLocation.distance(from: CLLocation(latitude: lat, longitude: lon)) / 1000
    }
}
