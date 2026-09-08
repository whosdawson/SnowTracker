import SwiftUI

struct ForecastRowView: View {
    let day: ForecastDay
    let units: UnitsPreference

    var body: some View {
        NavigationLink(value: day) {
            HStack {
                Text(day.weekdayLabel)
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)

                Image(systemName: WeatherCode.symbol(for: day.weatherCode))
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 28)

                if day.snowfall > 0 {
                    Label("\(formatted(day.snowfall)) \(units.snowSuffix)", systemImage: "snowflake")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 90, alignment: .leading)
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                }

                Spacer()

                Text("\(Int(day.lowTemp.rounded()))° / \(Int(day.highTemp.rounded()))°\(units.temperatureSuffix)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
