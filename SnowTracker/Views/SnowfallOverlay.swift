import SwiftUI

/// A subtle falling-snow ambience effect. Non-interactive, low-opacity —
/// atmosphere, not a distraction.
struct SnowfallOverlay: View {
    private let flakeCount = 14

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<flakeCount, id: \.self) { index in
                    SnowflakeParticle(containerSize: geo.size, seed: index)
                }
            }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

private struct SnowflakeParticle: View {
    let containerSize: CGSize
    let seed: Int

    @State private var fallen = false

    private var startX: CGFloat { CGFloat((seed * 37) % 100) / 100 * containerSize.width }
    private var size: CGFloat { CGFloat(6 + (seed % 4) * 3) }
    private var duration: Double { Double(8 + (seed % 5) * 2) }
    private var delay: Double { Double(seed % 7) * 0.6 }

    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundStyle(.white.opacity(0.35))
            .position(x: startX, y: fallen ? containerSize.height + 20 : -20)
            .onAppear {
                withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                    fallen = true
                }
            }
    }
}
