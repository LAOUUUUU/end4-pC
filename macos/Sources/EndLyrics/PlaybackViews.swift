import SpotifyKit
import SwiftUI

/// Row of bars driven by `VisualizerModel`. Each bar is one frequency band, low on the left.
struct VisualizerView: View {
    @ObservedObject var model: VisualizerModel

    private static let maxHeight: CGFloat = 36

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(model.bands.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 4, height: max(3, CGFloat(level) * Self.maxHeight))
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
