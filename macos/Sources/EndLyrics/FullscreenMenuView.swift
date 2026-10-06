import Appearance
import LyricsCore
import SwiftUI

/// The full-screen main menu: the cover as the whole background, big lyrics and cover art on the left,
/// and menu tiles on the right. Everything calls the same models and actions as the rest of the app.
struct FullscreenMenuView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    @ObservedObject var visualizer: VisualizerModel
    let actions: MainMenuController
    let close: () -> Void

    var body: some View {
        ZStack {
            CoverBackdrop(url: theme.artworkURL, colors: theme.backgroundColors)
                .ignoresSafeArea()
                .blur(radius: 0)

            HStack(alignment: .top, spacing: 40) {
                nowPlayingColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                tiles
                    .frame(width: 520)
            }
            .padding(48)

            VStack {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                Spacer()
            }
            .padding(20)
        }
        .foregroundStyle(.white)
    }

    private var nowPlayingColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom, spacing: 18) {
                AsyncImage(url: model.artworkURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1))
                }
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.4), radius: 18, y: 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(model.nowPlaying ?? "Nothing playing")
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(2)
                    Text(model.providerName.map { "Lyrics from \($0)" } ?? "Waiting for lyrics")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                    if let link = model.spotifyTrackURL {
                        Link("Open in Spotify", destination: link)
                            .font(.system(size: 12, weight: .medium))
                        Text("Cover art from Spotify")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }

            LyricsStack(model: model, theme: theme, font: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 12) {
                ProgressBarView(fraction: model.progress, accent: theme.accent) { model.seek(toFraction: $0) }
                VisualizerView(model: visualizer, theme: theme)
                VolumeSliderView(model: model, theme: theme)
                PlaybackControlsView(model: model, theme: theme)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            tile("play.fill", "Play / Pause", "Space") { model.togglePlayPause() }
            tile("rectangle.expand.vertical", "Now Playing", model.expanded ? "On" : "Off") { model.expanded.toggle() }
            tile("square.and.arrow.down", "Save .lrc", "Timed lyrics") { actions.saveLRC() }
            tile("doc.text", "Save .txt", "Plain lyrics") { actions.saveTXT() }
            tile("minus.circle", "Lyrics Earlier", "−0.25 s") { actions.offsetEarlier() }
            tile("plus.circle", "Lyrics Later", "+0.25 s") { actions.offsetLater() }
            tile("arrow.counterclockwise", "Reset Timing", "0 s") { actions.offsetReset() }
            tile("waveform", "Mirror Bars", theme.settings.style == .mirror ? "On" : "Off") {
                theme.settings.style = theme.settings.style == .mirror ? .bars : .mirror
            }
            tile("rectangle.compress.vertical", "Compact", theme.settings.compactMode ? "On" : "Off") {
                theme.settings.compactMode.toggle()
            }
            tile("hand.tap", "Click to Jump", theme.settings.clickToSeek ? "On" : "Off") {
                theme.settings.clickToSeek.toggle()
            }
            tile("gearshape", "Settings", "Player, colours, visualizer") { actions.settings() }
            tile("power", "Quit", "Close EndLyrics") { NSApp.terminate(nil) }
        }
    }

    private func tile(_ symbol: String, _ title: String, _ subtitle: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Spacer(minLength: 0)
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
