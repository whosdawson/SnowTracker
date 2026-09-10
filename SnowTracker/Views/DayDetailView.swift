import SwiftUI
import Charts

struct DayDetailView: View {
    let day: ForecastDay
    let units: UnitsPreference

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if !day.hourly.isEmpty {
                    hourlyStrip
                    snowfallChart
                }

                statGrid
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle(day.fullDateLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: WeatherCode.symbol(for: day.weatherCode))
                .font(.system(size: 48))
                .symbolRenderingMode(.multicolor)

            VStack(alignment: .leading, spacing: 4) {
                Text(WeatherCode.description(for: day.weatherCode))
                    .font(.title2.weight(.semibold))
                Text("H: \(Int(day.highTemp.rounded()))\(units.temperatureSuffix)   L: \(Int(day.lowTemp.rounded()))\(units.temperatureSuffix)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if day.snowfall > 0 {
                    Label("\(formatted(day.snowfall)) \(units.snowSuffix) expected", systemImage: "snowflake")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            Spacer()
        }
    }

    private var hourlyStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(day.hourly) { hour in
                    VStack(spacing: 6) {
                        Text(hour.hourLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: WeatherCode.symbol(for: hour.weatherCode))
                            .symbolRenderingMode(.multicolor)
                        Text("\(Int(hour.temperature.rounded()))°")
                            .font(.subheadline.weight(.medium))
                        if hour.snowfall > 0 {
                            Text(formatted(hour.snowfall))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var snowfallChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Snowfall by Hour")
                .font(.headline)
            Chart(day.hourly) { hour in
                BarMark(
                    x: .value("Hour", hour.hourLabel),
                    y: .value("Snowfall", hour.snowfall)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            stat(title: "Wind", value: "\(Int(day.windSpeed.rounded())) \(units.windSuffix)", icon: "wind")
            if let gusts = day.windGusts {
                stat(title: "Gusts", value: "\(Int(gusts.rounded())) \(units.windSuffix)", icon: "wind.snow")
            }
            if let precip = day.precipitationProbability {
                stat(title: "Precip. Chance", value: "\(precip)%", icon: "cloud.rain")
            }
            if let uv = day.uvIndexMax {
                stat(title: "UV Index", value: String(format: "%.0f", uv), icon: "sun.max")
            }
            if let sunrise = ForecastDay.timeLabel(day.sunrise) {
                stat(title: "Sunrise", value: sunrise, icon: "sunrise")
            }
            if let sunset = ForecastDay.timeLabel(day.sunset) {
                stat(title: "Sunset", value: sunset, icon: "sunset")
            }
        }
    }

    private func stat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
