import AudioVisualizer
import SwiftUI

/// The cover art, swelling and glowing with the bass. This is its own view, so the 30 fps
/// visualizer updates redraw only the cover, not the whole panel.
struct BeatCover: View {
    let url: URL?
    @ObservedObject var visualizer: VisualizerModel
    let accent: Color
    var size: CGFloat = 160

    var body: some View {
        let bass = CGFloat(BeatLevel.bass(from: visualizer.bands))
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(1 + bass * 0.04)
        .shadow(color: accent.opacity(0.2 + bass * 0.5), radius: 12 + bass * 24)
        .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
        .animation(.easeOut(duration: 0.12), value: bass)
    }
}
