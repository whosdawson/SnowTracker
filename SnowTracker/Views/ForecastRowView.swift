import SwiftUI

struct ForecastRowView: View {
    let day: ForecastDay
    let units: UnitsPreference
    /// Low/high across the whole visible forecast, so each day's temp bar
    /// is scaled consistently against the others (like Apple Weather).
    let weekLow: Double
    let weekHigh: Double

    var body: some View {
        NavigationLink(value: day) {
            HStack(spacing: 14) {
                Text(day.weekdayLabel)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 46, alignment: .leading)

                Image(systemName: WeatherCode.symbol(for: day.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 22))
                    .frame(width: 34)

                snowfallLabel
                    .frame(width: 54, alignment: .leading)

                Text("\(Int(day.lowTemp.rounded()))°")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)

                temperatureBar

                Text("\(Int(day.highTemp.rounded()))°\(units.temperatureSuffix)")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 58, alignment: .trailing)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var snowfallLabel: some View {
        if day.snowfall > 0 {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: "snowflake")
                    .font(.caption2)
                Text("\(formatted(day.snowfall))\(units.snowSuffix)")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.blue)
        } else {
            Text("—")
                .foregroundStyle(.secondary)
        }
    }

    private var temperatureBar: some View {
        GeometryReader { geo in
            let range = max(weekHigh - weekLow, 1)
            let startFraction = (day.lowTemp - weekLow) / range
            let endFraction = (day.highTemp - weekLow) / range
            let width = geo.size.width
            let startX = width * CGFloat(startFraction)
            let barWidth = max(width * CGFloat(endFraction - startFraction), 4)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: barWidth)
                    .offset(x: startX)
            }
        }
        .frame(height: 6)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
