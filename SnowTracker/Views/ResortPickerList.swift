import SwiftUI

/// Shared "search any resort" list used by both the Forecast and Cameras tabs.
/// Shows favorites + a curated popular list by default, and live worldwide
/// search results once the user starts typing.
struct ResortPickerList<Destination: View>: View {
    let title: String
    let searchPrompt: String
    @ViewBuilder let destination: (Resort) -> Destination

    @EnvironmentObject private var dataStore: ResortDataStore
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var searchText = ""
    @AppStorage("showPopularResorts") private var showPopularResorts = true

    var body: some View {
        List {
            if searchText.isEmpty {
                if !favorites.favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites.favorites) { resort in
                            row(for: resort)
                        }
                    }
                }
                Section {
                    if showPopularResorts {
                        ForEach(dataStore.popularResorts) { resort in
                            row(for: resort)
                        }
                    }
                } header: {
                    Button {
                        withAnimation { showPopularResorts.toggle() }
                    } label: {
                        HStack {
                            Text("Popular Resorts")
                            Spacer()
                            Image(systemName: showPopularResorts ? "chevron.up" : "chevron.down")
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Section("Results") {
                    if dataStore.isSearching {
                        HStack {
                            ProgressView()
                            Text("Searching…").foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)
                    } else if let error = dataStore.searchError {
                        Text(error).foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    } else if dataStore.searchResults.isEmpty {
                        Text("No resorts found for \"\(searchText)\".").foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(dataStore.searchResults) { resort in
                            row(for: resort)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .searchable(text: $searchText, prompt: searchPrompt)
        .navigationTitle(title)
        .navigationDestination(for: Resort.self) { resort in
            destination(resort)
        }
        .task(id: searchText) {
            await dataStore.search(searchText)
        }
    }

    private func row(for resort: Resort) -> some View {
        NavigationLink(value: resort) {
            ResortRowView(
                resort: resort,
                isFavorite: favorites.isFavorite(resort),
                onToggleFavorite: { favorites.toggle(resort) }
            )
        }
        .listRowBackground(Color.clear)
    }
}
