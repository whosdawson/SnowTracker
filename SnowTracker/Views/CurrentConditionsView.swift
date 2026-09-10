import SwiftUI

struct CurrentConditionsView: View {
    let current: CurrentConditions
    let units: UnitsPreference

    private var isSnowing: Bool { current.snowfallNow >= 0.5 }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: WeatherCode.symbol(for: current.weatherCode))
                    .font(.system(size: 44))
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(current.temperature.rounded()))\(units.temperatureSuffix)")
                        .font(.system(size: 34, weight: .semibold))
                    Text(WeatherCode.tagline(for: current.weatherCode, snowfallNow: current.snowfallNow))
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
            }

            Divider().overlay(.white.opacity(0.3))

            HStack {
                statTile(title: "Snow (this hr)", value: "\(formatted(current.snowfallNow)) \(units.snowSuffix)", icon: "snowflake")
                statTile(title: "Wind", value: "\(Int(current.windSpeed.rounded())) \(units.windSuffix)", icon: "wind")
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(
            ZStack {
                LinearGradient(
                    colors: WeatherCode.moodGradient(for: current.weatherCode),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Color.black.opacity(0.12)
                if isSnowing {
                    SnowfallOverlay()
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .opacity(0.85)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
