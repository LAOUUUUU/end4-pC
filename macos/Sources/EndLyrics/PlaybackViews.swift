import SpotifyKit
import SwiftUI

/// Row of bars driven by `VisualizerModel`. Each bar is one frequency band, low on the left,
/// with a cap that marks its recent peak.
struct VisualizerView: View {
    @ObservedObject var model: VisualizerModel

    private static let maxHeight: CGFloat = 36
    private static let fill = LinearGradient(
        colors: [.cyan.opacity(0.9), .white.opacity(0.9)],
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(zip(model.bands.indices, model.bands)), id: \.0) { index, level in
                let peak = CGFloat(model.peaks[index])
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Self.fill)
                        .frame(width: 4, height: max(3, CGFloat(level) * Self.maxHeight))
                    Rectangle()
                        .fill(.white)
                        .frame(width: 4, height: 2)
                        .offset(y: -(peak * Self.maxHeight))
                        .opacity(peak > 0.02 ? 1 : 0)
                }
                .frame(width: 4, height: Self.maxHeight, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.maxHeight, maxHeight: Self.maxHeight, alignment: .bottom)
    }
}

/// Previous, play/pause, next. Each button sends one command to Spotify, and only when it is running.
struct PlaybackControlsView: View {
    var body: some View {
        HStack(spacing: 22) {
            control("backward.fill", .previous)
            control("playpause.fill", .playPause)
            control("forward.fill", .next)
        }
        .frame(maxWidth: .infinity)
    }

    private func control(_ symbol: String, _ command: SpotifyCommand) -> some View {
        Button {
            Task { await command.send() }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
