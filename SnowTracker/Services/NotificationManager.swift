import Foundation
import UserNotifications

/// Checks favorited resorts for predicted snow and posts a local notification
/// when notable snow is coming in the next couple of days.
///
/// This runs whenever the app becomes active (see `SnowTrackerApp`), so it
/// catches up every time you open the app. It does not yet wake the app in
/// the background while closed — that would need a BGTaskScheduler refresh
/// task registered with an associated background mode.
final class NotificationManager {
    static let shared = NotificationManager()

    /// Minimum forecast snowfall (in cm) to count as "notable" and trigger a notification.
    private let snowThresholdCm: Double = 2.0
    private static let lastNotifiedKey = "lastSnowNotificationDates"

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Fetches a fresh, metric forecast for each favorite (independent of the
    /// user's display unit preference) and notifies about any with notable
    /// snow in the next 2 days — at most once per resort per day.
    func checkFavoritesForSnow(_ favorites: [Resort]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        var lastNotified = UserDefaults.standard.dictionary(forKey: Self.lastNotifiedKey) as? [String: String] ?? [:]
        let today = Self.dayKeyFormatter.string(from: Date())

        for resort in favorites {
            guard lastNotified[resort.id] != today else { continue }
            guard let snapshot = try? await WeatherService.shared.fetchSnapshot(for: resort, units: .metric) else { continue }

            let lookahead = Array(snapshot.daily.prefix(2))
            guard let bestIndex = lookahead.indices.max(by: { lookahead[$0].snowfall < lookahead[$1].snowfall }) else { continue }
            let bestDay = lookahead[bestIndex]
            guard bestDay.snowfall >= snowThresholdCm else { continue }

            let content = UNMutableNotificationContent()
            content.title = "❄️ Snow at \(resort.name)"
            let when = bestIndex == 0 ? "today" : "tomorrow"
            content.body = "\(String(format: "%.0f", bestDay.snowfall)) cm expected \(when)."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "snow-\(resort.id)-\(today)",
                content: content,
                trigger: nil
            )
            try? await center.add(request)

            lastNotified[resort.id] = today
        }

        UserDefaults.standard.set(lastNotified, forKey: Self.lastNotifiedKey)
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
