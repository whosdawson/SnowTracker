import Foundation

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

    func fetchWebcams(near resort: Resort, radiusKm: Int = 30, limit: Int = 12) async throws -> [Webcam] {
        guard WebcamAPIConfig.isConfigured else {
            throw WebcamServiceError.missingAPIKey
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "near", value: "\(resort.latitude),\(resort.longitude)"),
            URLQueryItem(name: "radius", value: "\(radiusKm)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "include", value: "images,location,urls"),
            URLQueryItem(name: "lang", value: "en"),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(WebcamAPIConfig.apiKey, forHTTPHeaderField: "x-windy-api-key")

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
        return (decoded.webcams ?? []).map { $0.asWebcam }
    }
}
