import SwiftUI

struct ResortDetailView: View {
    let resort: Resort

    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var unitsSettings: UnitsSettings

    @State private var snapshot: WeatherSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let snapshot {
                    CurrentConditionsView(current: snapshot.current, units: snapshot.units)
                        .padding(.horizontal)

                    NavigationLink {
                        WebcamGridView(resort: resort)
                    } label: {
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
                                ForecastRowView(day: day, units: snapshot.units)
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
                    ProgressView("Loading forecast…")
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
        .navigationTitle(resort.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    WebcamGridView(resort: resort)
                } label: {
                    Image(systemName: "video")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    favorites.toggle(resort)
                } label: {
                    Image(systemName: favorites.isFavorite(resort) ? "star.fill" : "star")
                        .foregroundStyle(favorites.isFavorite(resort) ? .yellow : .primary)
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
