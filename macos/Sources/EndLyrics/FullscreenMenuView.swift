import Appearance
import LyricsCore
import SwiftUI

/// The full-screen main menu: the cover as the whole background, big lyrics and cover art on the left,
/// and widgets with menu tiles on the right. Columns are sized from the window, so it fits any screen.
struct FullscreenMenuView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    @ObservedObject var visualizer: VisualizerModel
    @ObservedObject var hub: WidgetHub
    @ObservedObject var navigator: FullscreenNavigator
    let actions: MainMenuController
    let close: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let margin: CGFloat = 40
            let rightWidth = min(460, max(300, geometry.size.width * 0.34))
            let lyricSize = min(30, max(16, geometry.size.height / 24))

            ZStack(alignment: .topTrailing) {
                CoverBackdrop(url: theme.artworkURL, colors: theme.backgroundColors, blur: theme.settings.backgroundBlur, imagePath: theme.settings.backgroundImagePath)
                    .ignoresSafeArea()

                Group {
                if navigator.page == .settings {
                    ScrollView(.vertical, showsIndicators: false) {
                        SettingsView(theme: theme)
                            .frame(maxWidth: 640, alignment: .leading)
                            .padding(.bottom, 24)
                    }
                } else {
                    HStack(alignment: .top, spacing: 32) {
                        nowPlayingColumn(lyricSize: lyricSize)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                WidgetsView(hub: hub, theme: theme)
                                tiles
                            }
                            .padding(.bottom, 24)
                        }
                        .frame(width: rightWidth)
                    }
                }
                }
                .padding(.horizontal, margin)
                .padding(.top, 56)
                .padding(.bottom, margin)

                HStack(spacing: 10) {
                    pageSwitch
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 14)
                .padding(.trailing, 18)
            }
        }
        .foregroundStyle(.white)
    }

    /// Home and Settings, shown in the same window.
    private var pageSwitch: some View {
        HStack(spacing: 4) {
            ForEach([(FullscreenPage.home, "Home"), (FullscreenPage.settings, "Settings")], id: \.1) { page, title in
                Button(title) { navigator.page = page }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(navigator.page == page ? theme.accent.opacity(0.35) : .white.opacity(0.08)))
            }
        }
        .padding(4)
        .background(Capsule().fill(.black.opacity(0.25)))
    }

    private func nowPlayingColumn(lyricSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 18) {
                AsyncImage(url: model.artworkURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1))
                }
                .frame(width: 160, height: 160)
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

            LyricsStack(model: model, theme: theme, baseFont: lyricSize)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 12) {
                ProgressBarView(fraction: model.progress, accent: theme.accent) { model.seek(toFraction: $0) }
                VisualizerView(model: visualizer, theme: theme, height: 56)
                VolumeSliderView(model: model, theme: theme)
                PlaybackControlsView(model: model, theme: theme)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
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
            tile("gearshape", "Settings", "Player, colours, bars") { navigator.page = .settings }
            tile("doc.on.doc", "Copy Lyric", "Current line") { actions.copyCurrentLyric() }
            tile("doc.on.clipboard", "Copy Lyrics", "Whole song") { actions.copyAllLyrics() }
            tile("power", "Quit", "Close EndLyrics") { NSApp.terminate(nil) }
        }
    }

    private func tile(_ symbol: String, _ title: String, _ subtitle: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Spacer(minLength: 0)
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
