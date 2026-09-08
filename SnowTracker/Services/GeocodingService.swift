import Foundation

/// Looks up any place worldwide (resort, mountain, or town) by name using Open-Meteo's
/// free geocoding API — no API key required: https://open-meteo.com/en/docs/geocoding-api
struct GeocodingService {
    static let shared = GeocodingService()

    private let baseURL = "https://geocoding-api.open-meteo.com/v1/search"

    func search(query: String, count: Int = 15) async throws -> [Resort] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherServiceError.requestFailed
        }

        let decoded = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        return (decoded.results ?? []).map { $0.asResort }
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

private struct GeocodingResult: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let country: String?
    let admin1: String?

    var asResort: Resort {
        Resort(
            id: "geo-\(id)",
            name: name,
            region: admin1 ?? country ?? "",
            country: country ?? "",
            latitude: latitude,
            longitude: longitude,
            elevationMeters: elevation ?? 0
        )
    }
}
