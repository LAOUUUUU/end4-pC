import Appearance
import AudioVisualizer
import LyricsCore
import SwiftUI

/// The full-screen main menu: the cover as the whole background, big lyrics and cover art on the left,
/// and widgets with menu tiles on the right. Columns are sized from the window, so it fits any screen.
struct FullscreenMenuView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    let visualizer: VisualizerModel
    @ObservedObject var hub: WidgetHub
    @ObservedObject var chat: AIChatModel
    @ObservedObject var navigator: FullscreenNavigator
    let actions: MainMenuController
    let close: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let margin: CGFloat = 40
            let rightWidth = min(460, max(300, geometry.size.width * 0.34))
            let lyricSize = min(30, max(16, geometry.size.height / 24))

            // Without an explicit size, the ZStack just grows to fit its content, so the settings
            // ScrollView never gets a bounded height to clip against and cannot scroll.
            ZStack(alignment: .topTrailing) {
                CoverBackdrop(url: theme.artworkURL, colors: theme.backgroundColors, blur: theme.settings.backgroundBlur, imagePath: theme.settings.backgroundImagePath)
                    .equatable()
                    .ignoresSafeArea()
                AmbientOrbs(colors: theme.backgroundColors)
                    .ignoresSafeArea()

                Group {
                if navigator.page == .settings {
                    ScrollView(.vertical, showsIndicators: false) {
                        SettingsView(theme: theme)
                            .frame(maxWidth: 640, alignment: .leading)
                            .padding(.bottom, 24)
                    }
                } else if navigator.page == .ai {
                    AIChatView(chat: chat, theme: theme) { navigator.page = .settings }
                        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .leading)
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
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .foregroundStyle(.white)
    }

    /// Home and Settings, shown in the same window.
    private var pageSwitch: some View {
        HStack(spacing: 4) {
            ForEach([(FullscreenPage.home, "Home"), (FullscreenPage.ai, "Ai"), (FullscreenPage.settings, "Settings")], id: \.1) { page, title in
                Button(title) { navigator.page = page }
                    .buttonStyle(RippleButtonStyle(radius: 12, toggled: navigator.page == page, accent: theme.accent))
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .padding(4)
        .background(Capsule().fill(.black.opacity(0.25)))
    }

    private func nowPlayingColumn(lyricSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 18) {
                BeatCover(url: model.artworkURL, visualizer: visualizer, accent: theme.accent, size: 160)

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

            VStack(alignment: .leading, spacing: 4) {
                LyricsStack(model: model, theme: theme, baseFont: lyricSize)
                if #available(macOS 15.0, *), theme.settings.translateLyrics {
                    TranslatedLine(text: model.currentLineText, targetCode: theme.settings.translationLanguage.isEmpty ? nil : theme.settings.translationLanguage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 12) {
                ProgressBarView(fraction: model.progress, accent: theme.accent) { model.seek(toFraction: $0) }
                VisualizerView(model: visualizer, theme: theme, height: 56)
                VolumeSliderView(model: model, theme: theme)
                PlaybackControlsView(model: model, theme: theme)
            }
        }
    }

    /// The actions that are not already in the controls, the header, Settings or the menu bar.
    private var tiles: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                tile("square.and.arrow.down", "Save .lrc", "Timed") { actions.saveLRC() }
                tile("doc.text", "Save .txt", "Plain") { actions.saveTXT() }
                tile("doc.on.clipboard", "Copy Lyrics", "Whole song") { actions.copyAllLyrics() }
                tile("gearshape", "Settings", "All options") { navigator.page = .settings }
            tile("bubble.left.and.bubble.right", "Ask Claude", "AI chat") { navigator.page = .ai }
            }
            timingCard
        }
    }

    /// Nudges the lyric timing in quarter-second steps, with a reset.
    private var timingCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Lyric timing").font(.system(size: 12, weight: .semibold))
                Text(String(format: "%+.2f s", theme.settings.lyricOffset))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer(minLength: 0)
            Button { actions.offsetEarlier() } label: { Image(systemName: "minus").frame(width: 22, height: 20) }
                .buttonStyle(RippleButtonStyle(radius: 6))
            Button { actions.offsetReset() } label: { Image(systemName: "arrow.counterclockwise").frame(width: 22, height: 20) }
                .buttonStyle(RippleButtonStyle(radius: 6))
            Button { actions.offsetLater() } label: { Image(systemName: "plus").frame(width: 22, height: 20) }
                .buttonStyle(RippleButtonStyle(radius: 6))
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12)))
    }

    private func tile(_ symbol: String, _ title: String, _ subtitle: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(subtitle).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(RippleButtonStyle(radius: 12))
    }
}

/// Slow drifting colour orbs behind the menu, in the cover's colours.
struct AmbientOrbs: View {
    let colors: [Color]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { index, color in
                        let phase = t * 0.05 + Double(index) * 2.1
                        Circle()
                            .fill(color.opacity(0.35))
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                            .blur(radius: 90)
                            .offset(
                                x: CGFloat(sin(phase)) * geometry.size.width * 0.3,
                                y: CGFloat(cos(phase * 0.8)) * geometry.size.height * 0.3
                            )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}
