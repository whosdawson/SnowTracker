import Foundation
import Combine

/// Persists the user's favorited resorts (full resort data, since resorts can come
/// from a live search and not just the bundled catalog).
final class FavoritesStore: ObservableObject {
    private static let storageKey = "favoriteResorts"

    @Published private(set) var favorites: [Resort] = []

    init() {
        load()
    }

    func isFavorite(_ resort: Resort) -> Bool {
        favorites.contains { $0.id == resort.id }
    }

    func toggle(_ resort: Resort) {
        if let index = favorites.firstIndex(where: { $0.id == resort.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(resort)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([Resort].self, from: data) else { return }
        favorites = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
