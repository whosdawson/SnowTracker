import Foundation

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Couldn't build the weather request."
        case .requestFailed: return "Couldn't reach the weather service. Check your connection and try again."
        }
    }
}

/// Fetches current conditions and a multi-day forecast from the free Open-Meteo API.
/// No API key required: https://open-meteo.com
struct WeatherService {
    static let shared = WeatherService()

    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    func fetchSnapshot(for resort: Resort, units: UnitsPreference) async throws -> WeatherSnapshot {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: "\(resort.latitude)"),
            URLQueryItem(name: "longitude", value: "\(resort.longitude)"),
            URLQueryItem(name: "elevation", value: "\(resort.elevationMeters)"),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,snowfall"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,snowfall_sum,wind_speed_10m_max,wind_gusts_10m_max,precipitation_probability_max,uv_index_max,sunrise,sunset"),
            URLQueryItem(name: "hourly", value: "temperature_2m,snowfall,weather_code,wind_speed_10m"),
            URLQueryItem(name: "temperature_unit", value: units.temperatureUnit),
            URLQueryItem(name: "wind_speed_unit", value: units.windSpeedUnit),
            URLQueryItem(name: "precipitation_unit", value: units.precipitationUnit),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw WeatherServiceError.requestFailed
            }
            data = responseData
        } catch {
            throw WeatherServiceError.requestFailed
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return Self.mapToSnapshot(decoded, units: units)
    }

    private static func mapToSnapshot(_ response: OpenMeteoResponse, units: UnitsPreference) -> WeatherSnapshot {
        let current = CurrentConditions(
            temperature: response.current.temperature2m,
            weatherCode: response.current.weatherCode,
            windSpeed: response.current.windSpeed10m,
            snowfallNow: response.current.snowfall
        )

        // Group hourly points by their date (the "yyyy-MM-dd" prefix of each
        // hourly timestamp) so each ForecastDay can carry its own 24 hours.
        var hourlyByDate: [String: [HourlyForecast]] = [:]
        if let hourly = response.hourly {
            for index in hourly.time.indices {
                let dateKey = String(hourly.time[index].prefix(10))
                let point = HourlyForecast(
                    timeString: hourly.time[index],
                    temperature: hourly.temperature2m[index],
                    snowfall: hourly.snowfall[index],
                    weatherCode: hourly.weatherCode[index],
                    windSpeed: hourly.windSpeed10m[index]
                )
                hourlyByDate[dateKey, default: []].append(point)
            }
        }

        let daily = response.daily.time.indices.map { index -> ForecastDay in
            let dateKey = response.daily.time[index]
            return ForecastDay(
                dateString: dateKey,
                weatherCode: response.daily.weatherCode[index],
                highTemp: response.daily.temperature2mMax[index],
                lowTemp: response.daily.temperature2mMin[index],
                snowfall: response.daily.snowfallSum[index],
                windSpeed: response.daily.windSpeed10mMax[index],
                windGusts: response.daily.windGusts10mMax?[safe: index],
                precipitationProbability: response.daily.precipitationProbabilityMax?[safe: index],
                uvIndexMax: response.daily.uvIndexMax?[safe: index],
                sunrise: response.daily.sunrise?[safe: index],
                sunset: response.daily.sunset?[safe: index],
                hourly: hourlyByDate[dateKey] ?? []
            )
        }

        return WeatherSnapshot(current: current, daily: daily, units: units)
    }
}
