import Foundation
import Combine

enum UnitsPreference: String, CaseIterable {
    case metric
    case imperial

    var label: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }

    var temperatureUnit: String { self == .metric ? "celsius" : "fahrenheit" }
    var windSpeedUnit: String { self == .metric ? "kmh" : "mph" }
    /// Open-Meteo's precipitation_unit also controls the unit snowfall is reported in
    /// (cm for "mm", inch for "inch").
    var precipitationUnit: String { self == .metric ? "mm" : "inch" }

    var temperatureSuffix: String { self == .metric ? "°C" : "°F" }
    var snowSuffix: String { self == .metric ? "cm" : "in" }
    var windSuffix: String { self == .metric ? "km/h" : "mph" }
}

/// Persists the user's preferred display units across launches.
final class UnitsSettings: ObservableObject {
    private static let storageKey = "unitsPreference"

    @Published var preference: UnitsPreference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.preference = stored.flatMap(UnitsPreference.init(rawValue:)) ?? .imperial
    }

    func toggle() {
        preference = preference == .metric ? .imperial : .metric
    }
}
