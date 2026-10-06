import Appearance
import AudioVisualizer
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
        let mirror = settings.style == .mirror
        let count = mirror ? settings.barCount * 2 : settings.barCount
        let resampledLevels = BandResampler.resample(model.bands, to: settings.barCount)
        let resampledPeaks = BandResampler.resample(model.peaks, to: settings.barCount)
        let levels = mirror ? BandLayout.mirrored(resampledLevels) : resampledLevels
        let peaks = mirror ? BandLayout.mirrored(resampledPeaks) : resampledPeaks
        let barWidth: CGFloat = count > 24 ? 3 : 4
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

/// Shuffle, previous, play/pause, next, repeat. Each button sends one command to Spotify,
/// and only when it is running. Shuffle and repeat show their current state in the accent colour.
struct PlaybackControlsView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel

    var body: some View {
        HStack(spacing: 18) {
            toggle("shuffle", on: model.shuffling) { model.toggleShuffle() }
            control("backward.fill", .previous)
            control("playpause.fill", .playPause)
            control("forward.fill", .next)
            toggle("repeat", on: model.repeating) { model.toggleRepeat() }
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
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ symbol: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(on ? theme.accent : .white.opacity(0.45))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Thin bar showing how far through the track playback is.
struct ProgressBarView: View {
    let fraction: Double
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(accent)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: 3)
    }
}
