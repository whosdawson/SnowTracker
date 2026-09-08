import Foundation

// MARK: - App-facing models

struct CurrentConditions {
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    /// Snowfall recorded in the current hour.
    let snowfallNow: Double
}

struct ForecastDay: Identifiable {
    let id = UUID()
    let dateString: String
    let weatherCode: Int
    let highTemp: Double
    let lowTemp: Double
    let snowfall: Double
    let windSpeed: Double

    /// Short weekday label, e.g. "Mon", computed from the "yyyy-MM-dd" date string.
    var weekdayLabel: String {
        guard let date = ForecastDay.dayFormatter.date(from: dateString) else { return dateString }
        return ForecastDay.weekdayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}

struct WeatherSnapshot {
    let current: CurrentConditions
    let daily: [ForecastDay]
    let units: UnitsPreference

    /// Total expected snowfall over the forecast window.
    var totalSnowfall: Double {
        daily.reduce(0) { $0 + $1.snowfall }
    }
}

/// Maps Open-Meteo's WMO weather codes to an SF Symbol and short description.
enum WeatherCode {
    static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1, 2: return "cloud.sun"
        case 3: return "cloud"
        case 45, 48: return "cloud.fog"
        case 51, 53, 55: return "cloud.drizzle"
        case 56, 57: return "cloud.sleet"
        case 61, 63, 65: return "cloud.rain"
        case 66, 67: return "cloud.sleet"
        case 71, 73, 75, 77: return "snowflake"
        case 80, 81, 82: return "cloud.heavyrain"
        case 85, 86: return "cloud.snow"
        case 95: return "cloud.bolt"
        case 96, 99: return "cloud.bolt.rain"
        default: return "questionmark"
        }
    }

    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mostly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm w/ hail"
        default: return "Unknown"
        }
    }
}

// MARK: - Open-Meteo API response (decoding layer)

struct OpenMeteoResponse: Decodable {
    let current: CurrentBlock
    let daily: DailyBlock
}

struct CurrentBlock: Decodable {
    let temperature2m: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let snowfall: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case snowfall
    }
}

struct DailyBlock: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let snowfallSum: [Double]
    let windSpeed10mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case snowfallSum = "snowfall_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
    }
}
