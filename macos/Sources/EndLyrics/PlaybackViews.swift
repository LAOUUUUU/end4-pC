import AudioVisualizer
import Appearance
import SpotifyKit
import SwiftUI

/// Row of bars driven by `VisualizerModel`, shaped by the user's settings: bar count,
/// peak caps, and the accent colour from the cover art or the chosen solid colour.
struct VisualizerView: View {
    @ObservedObject var model: VisualizerModel
    @ObservedObject var theme: ThemeModel

    private static let maxHeight: CGFloat = 36

    var body: some View {
        let settings = theme.settings
        let levels = BandResampler.resample(model.bands, to: settings.barCount)
        let peaks = BandResampler.resample(model.peaks, to: settings.barCount)
        let barWidth: CGFloat = settings.barCount > 24 ? 3 : 4
        let fill = LinearGradient(
            colors: [theme.accent.opacity(0.9), .white.opacity(0.9)],
            startPoint: .bottom,
            endPoint: .top
        )

        HStack(alignment: .bottom, spacing: 3) {
            ForEach(levels.indices, id: \.self) { index in
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(fill)
                        .frame(width: barWidth, height: max(3, CGFloat(levels[index]) * Self.maxHeight))
                    if settings.showPeakCaps {
                        let peak = CGFloat(peaks[index])
                        Rectangle()
                            .fill(.white)
                            .frame(width: barWidth, height: 2)
                            .offset(y: -(peak * Self.maxHeight))
                            .opacity(peak > 0.02 ? 1 : 0)
                    }
                }
                .frame(width: barWidth, height: Self.maxHeight, alignment: .bottom)
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
