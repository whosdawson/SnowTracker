import SwiftUI

struct CurrentConditionsView: View {
    let current: CurrentConditions
    let units: UnitsPreference

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: WeatherCode.symbol(for: current.weatherCode))
                    .font(.system(size: 44))
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(current.temperature.rounded()))\(units.temperatureSuffix)")
                        .font(.system(size: 34, weight: .semibold))
                    Text(WeatherCode.description(for: current.weatherCode))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            HStack {
                statTile(title: "Snow (this hr)", value: "\(formatted(current.snowfallNow)) \(units.snowSuffix)", icon: "snowflake")
                statTile(title: "Wind", value: "\(Int(current.windSpeed.rounded())) \(units.windSuffix)", icon: "wind")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }

    private func statTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
