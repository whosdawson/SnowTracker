import SwiftUI

/// A small pill showing whether a resort is open, opening soon, or closed
/// for the season. Renders nothing for `.unknown`.
struct SeasonStatusBadge: View {
    let status: SeasonStatus

    var body: some View {
        if let text = Self.text(for: status) {
            Text(text)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Self.tint(for: status).opacity(0.15))
                .foregroundStyle(Self.tint(for: status))
                .clipShape(Capsule())
        }
    }

    private static func text(for status: SeasonStatus) -> String? {
        switch status {
        case .open:
            return "Open Now"
        case .opensOn(let date):
            return "Opens \(dateFormatter.string(from: date))"
        case .closedForSeason:
            return "Season Closed"
        case .unknown:
            return nil
        }
    }

    private static func tint(for status: SeasonStatus) -> Color {
        switch status {
        case .open: return .green
        case .opensOn: return .blue
        case .closedForSeason: return .secondary
        case .unknown: return .clear
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
