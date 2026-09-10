import SwiftUI

struct ResortDetailView: View {
    let resort: Resort

    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var unitsSettings: UnitsSettings

    @State private var snapshot: WeatherSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loadingPhrase = ResortDetailView.loadingPhrases.randomElement()!

    private static let loadingPhrases = [
        "Waxing the board…", "Checking the lifts…", "Scouting fresh tracks…",
        "Dusting off the goggles…", "Reading the snow report…",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if resort.seasonStatus != .unknown {
                    SeasonStatusBadge(status: resort.seasonStatus)
                        .padding(.horizontal)
                }

                if let snapshot {
                    CurrentConditionsView(current: snapshot.current, units: snapshot.units)
                        .padding(.horizontal)

                    NavigationLink(value: WebcamGridRoute(resort: resort)) {
                        HStack {
                            Label("Live Cameras", systemImage: "video.fill")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("7-Day Forecast")
                                .font(.headline)
                            Spacer()
                            Text("Total: \(String(format: "%.1f", snapshot.totalSnowfall)) \(snapshot.units.snowSuffix)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(snapshot.daily) { day in
                                ForecastRowView(
                                    day: day,
                                    units: snapshot.units,
                                    weekLow: weekLow(in: snapshot),
                                    weekHigh: weekHigh(in: snapshot)
                                )
                                .padding(.horizontal)
                                if day.id != snapshot.daily.last?.id {
                                    Divider().padding(.leading)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 16).fill(.thinMaterial))
                        .padding(.horizontal)
                    }
                } else if isLoading {
                    ProgressView(loadingPhrase)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await load() }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                }
            }
            .padding(.top)
        }
        .background(AppBackground())
        .navigationTitle(resort.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: WebcamGridRoute(resort: resort)) {
                    Image(systemName: "video")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Haptics.toggle()
                    favorites.toggle(resort)
                } label: {
                    Image(systemName: favorites.isFavorite(resort) ? "star.fill" : "star")
                        .foregroundStyle(favorites.isFavorite(resort) ? .yellow : .primary)
                        .scaleEffect(favorites.isFavorite(resort) ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: favorites.isFavorite(resort))
                }
            }
        }
        .task(id: unitsSettings.preference) {
            await load()
        }
        .refreshable {
            await load()
        }
    }

    private func weekLow(in snapshot: WeatherSnapshot) -> Double {
        snapshot.daily.map(\.lowTemp).min() ?? 0
    }

    private func weekHigh(in snapshot: WeatherSnapshot) -> Double {
        snapshot.daily.map(\.highTemp).max() ?? 0
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            snapshot = try await WeatherService.shared.fetchSnapshot(for: resort, units: unitsSettings.preference)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
