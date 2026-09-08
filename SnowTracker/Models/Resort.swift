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

    var subtitle: String {
        "\(region), \(country)"
    }
}
