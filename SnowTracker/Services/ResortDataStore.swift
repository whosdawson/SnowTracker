import Foundation
import Combine

/// Loads the bundled "popular resorts" catalog for quick browsing, and performs
/// live worldwide search (via GeocodingService) so the user can find any resort by name.
final class ResortDataStore: ObservableObject {
    @Published private(set) var popularResorts: [Resort] = []
    @Published private(set) var loadError: String?

    @Published private(set) var searchResults: [Resort] = []
    @Published private(set) var isSearching = false
    @Published private(set) var searchError: String?

    init() {
        loadPopularResorts()
    }

    private func loadPopularResorts() {
        guard let url = Bundle.main.url(forResource: "resorts", withExtension: "json") else {
            loadError = "Resort catalog is missing from the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            popularResorts = try JSONDecoder().decode([Resort].self, from: data)
                .sorted { $0.name < $1.name }
        } catch {
            loadError = "Couldn't load resort catalog: \(error.localizedDescription)"
        }
    }

    /// Searches any resort/mountain/town worldwide. Call from a `.task(id: query)`
    /// so SwiftUI cancels stale in-flight searches as the user keeps typing.
    @MainActor
    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }

        isSearching = true
        searchError = nil
        do {
            // Small debounce so we don't fire a request per keystroke.
            try await Task.sleep(nanoseconds: 300_000_000)
            let results = try await GeocodingService.shared.search(query: trimmed)
            if Task.isCancelled { return }
            searchResults = results
        } catch is CancellationError {
            // Superseded by a newer search; leave state alone.
        } catch {
            if !Task.isCancelled {
                searchError = "Couldn't search resorts. Check your connection."
                searchResults = []
            }
        }
        isSearching = false
    }
}
