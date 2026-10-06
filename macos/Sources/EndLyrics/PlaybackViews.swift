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
            playPause
            control("forward.fill", .next)
            toggle("repeat", on: model.repeating) { model.toggleRepeat() }
        }
        .frame(maxWidth: .infinity)
    }

    /// Play and pause share one button. The icon morphs between the two states.
    private var playPause: some View {
        Button {
            model.togglePlayPause()
        } label: {
            Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 30, height: 26)
                .contentTransition(.symbolEffect(.replace))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

/// Thin bar showing how far through the track playback is. Click or drag to seek.
struct ProgressBarView: View {
    let fraction: Double
    let accent: Color
    var onSeek: ((Double) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(accent)
                    .frame(width: geometry.size.width * fraction)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard geometry.size.width > 0 else { return }
                        onSeek?(value.location.x / geometry.size.width)
                    }
            )
        }
        .frame(height: 10)
    }
}

/// Volume from 0 to 100. The level is sent to Spotify when the drag ends.
struct VolumeSliderView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
            Slider(value: $model.volume, in: 0...100) { editing in
                model.volumeEditing = editing
                if !editing {
                    model.setVolume(model.volume)
                }
            }
            .tint(theme.accent)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
