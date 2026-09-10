import Foundation

/// A ski resort or mountain that can be searched for and tracked.
struct Resort: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let region: String
    let country: String
    let latitude: Double
    let longitude: Double
    /// Base elevation in meters, used to correct the weather model's temperature/snow estimate.
    let elevationMeters: Double

    /// Official resort webcam page, curated by hand for well-known resorts.
    /// Resorts found via live search won't have one, which is expected.
    let officialWebcamURL: String?
    /// Planned opening/closing date for the current season, "yyyy-MM-dd".
    /// Curated for a subset of resorts; nil means unknown rather than closed.
    let plannedOpeningDate: String?
    let plannedClosingDate: String?

    // A default *property* value here (e.g. `= nil`) would silently break
    // JSON decoding: Swift's synthesized Decodable ignores the JSON value
    // entirely and always uses the default instead, for that property.
    // A custom initializer with default *parameter* values doesn't have
    // that problem, and still lets GeocodingService build a Resort (for
    // live-searched resorts) without specifying these three.
    init(
        id: String, name: String, region: String, country: String,
        latitude: Double, longitude: Double, elevationMeters: Double,
        officialWebcamURL: String? = nil,
        plannedOpeningDate: String? = nil,
        plannedClosingDate: String? = nil
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.officialWebcamURL = officialWebcamURL
        self.plannedOpeningDate = plannedOpeningDate
        self.plannedClosingDate = plannedClosingDate
    }

    var subtitle: String {
        "\(region), \(country)"
    }

    /// Whether the resort is open, not yet open, or closed for the season,
    /// derived from the curated planned dates. `.unknown` when we don't have
    /// dates for this resort — that's a normal, honest state, not an error.
    var seasonStatus: SeasonStatus {
        let today = Date()
        let opening = plannedOpeningDate.flatMap(Resort.dateFormatter.date(from:))
        let closing = plannedClosingDate.flatMap(Resort.dateFormatter.date(from:))

        if let closing, today > closing {
            return .closedForSeason(closing)
        }
        if let opening, today < opening {
            return .opensOn(opening)
        }
        if opening != nil || closing != nil {
            return .open
        }
        return .unknown
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}

enum SeasonStatus: Equatable {
    case open
    case opensOn(Date)
    case closedForSeason(Date)
    case unknown
}
