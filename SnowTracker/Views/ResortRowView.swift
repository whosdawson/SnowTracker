import SwiftUI

struct ResortRowView: View {
    let resort: Resort
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(resort.name)
                    .font(.body)
                Text(resort.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            SeasonStatusBadge(status: resort.seasonStatus)
            Button {
                Haptics.toggle()
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                    .scaleEffect(isFavorite ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isFavorite)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
