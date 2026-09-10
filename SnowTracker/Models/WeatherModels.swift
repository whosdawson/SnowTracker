import Foundation
import SwiftUI

// MARK: - App-facing models

struct CurrentConditions {
    let temperature: Double
    let weatherCode: Int
    let windSpeed: Double
    /// Snowfall recorded in the current hour.
    let snowfallNow: Double
}

struct HourlyForecast: Identifiable, Hashable {
    let id = UUID()
    /// "yyyy-MM-dd'T'HH:mm"
    let timeString: String
    let temperature: Double
    let snowfall: Double
    let weatherCode: Int
    let windSpeed: Double

    /// Short hour label, e.g. "2 PM".
    var hourLabel: String {
        guard let date = HourlyForecast.formatter.date(from: timeString) else { return timeString }
        return HourlyForecast.labelFormatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let labelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}

struct ForecastDay: Identifiable, Hashable {
    let id = UUID()
    let dateString: String
    let weatherCode: Int
    let highTemp: Double
    let lowTemp: Double
    let snowfall: Double
    let windSpeed: Double
    let windGusts: Double?
    let precipitationProbability: Int?
    let uvIndexMax: Double?
    /// "yyyy-MM-dd'T'HH:mm"
    let sunrise: String?
    let sunset: String?
    let hourly: [HourlyForecast]

    /// Short weekday label, e.g. "Mon", computed from the "yyyy-MM-dd" date string.
    var weekdayLabel: String {
        guard let date = ForecastDay.dayFormatter.date(from: dateString) else { return dateString }
        return ForecastDay.weekdayFormatter.string(from: date)
    }

    /// Full label, e.g. "Wednesday, Nov 20".
    var fullDateLabel: String {
        guard let date = ForecastDay.dayFormatter.date(from: dateString) else { return dateString }
        return ForecastDay.fullDateFormatter.string(from: date)
    }

    static func timeLabel(_ timeString: String?) -> String? {
        guard let timeString, let date = HourlyForecast.timeParser.date(from: timeString) else { return nil }
        return HourlyForecast.timeLabelFormatter.string(from: date)
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

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}

// fileprivate (not private) so ForecastDay.timeLabel, in the same file, can use these too.
fileprivate extension HourlyForecast {
    static let timeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    static let timeLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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

    /// A mood gradient for the "current conditions" card, so each weather
    /// type has its own visual character instead of one flat card style.
    static func moodGradient(for code: Int) -> [Color] {
        switch code {
        case 0: return [.orange, .yellow]
        case 1, 2: return [.blue, .cyan]
        case 3: return [.gray, .blue.opacity(0.6)]
        case 45, 48: return [.gray, Color.white.opacity(0.6)]
        case 51, 53, 55, 61, 63, 65, 80, 81, 82: return [.blue, .indigo]
        case 71, 73, 75, 77, 85, 86: return [.cyan, .indigo]
        case 95, 96, 99: return [.purple, .indigo]
        default: return [.blue, .cyan]
        }
    }

    /// A short, personable read on current conditions.
    static func tagline(for code: Int, snowfallNow: Double) -> String {
        if snowfallNow >= 0.5 { return "Snowing right now ❄️" }
        switch code {
        case 0: return "Bluebird skies ☀️"
        case 1, 2: return "Mostly clear up there"
        case 3: return "Overcast, but chill"
        case 45, 48: return "Foggy on the mountain"
        case 51, 53, 55, 61, 63, 65, 80, 81, 82: return "Wet out there"
        case 71, 73, 75, 77, 85, 86: return "Snowing right now ❄️"
        case 95, 96, 99: return "Stormy — ride safe"
        default: return "Check conditions"
        }
    }
}

// MARK: - Open-Meteo API response (decoding layer)

struct OpenMeteoResponse: Decodable {
    let current: CurrentBlock
    let daily: DailyBlock
    let hourly: HourlyBlock?
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
    let windGusts10mMax: [Double]?
    let precipitationProbabilityMax: [Int]?
    let uvIndexMax: [Double]?
    let sunrise: [String]?
    let sunset: [String]?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case snowfallSum = "snowfall_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case uvIndexMax = "uv_index_max"
        case sunrise
        case sunset
    }
}

struct HourlyBlock: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let snowfall: [Double]
    let weatherCode: [Int]
    let windSpeed10m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case snowfall
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

extension Array {
    /// Returns nil instead of crashing when the index is out of bounds —
    /// used for the optional daily-detail arrays, which may come back
    /// shorter than `time` if Open-Meteo omits a field.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
