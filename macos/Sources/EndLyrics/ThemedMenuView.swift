import Appearance
import LyricsCore
import SwiftUI

/// The main menu opened from the ♪ item: a themed popover with the cover as its background,
/// the now-playing header, the playback controls, and every menu action as a row.
struct ThemedMenuView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    let actions: MainMenuController
    let showSettings: () -> Void
    let toggleWindow: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ProgressBarView(fraction: model.progress, accent: theme.accent) { model.seek(toFraction: $0) }
            VolumeSliderView(model: model, theme: theme)
            PlaybackControlsView(model: model, theme: theme)

            section("Window") {
                row("macwindow", "Show / Hide Lyrics Window", toggleWindow)
                row("rectangle.expand.vertical", "Now Playing Layout", { model.expanded.toggle() })
                toggleRow("rectangle.compress.vertical", "Compact Mode", theme.settings.compactMode) {
                    theme.settings.compactMode.toggle()
                }
                toggleRow("waveform", "Mirror Visualizer", theme.settings.style == .mirror) {
                    theme.settings.style = theme.settings.style == .mirror ? .bars : .mirror
                }
            }

            section("Lyrics") {
                row("square.and.arrow.down", "Save as .lrc…") { actions.saveLRC() }
                row("doc.text", "Save as .txt…") { actions.saveTXT() }
                row("minus.circle", "Timing Earlier (−0.25 s)") { actions.offsetEarlier() }
                row("plus.circle", "Timing Later (+0.25 s)") { actions.offsetLater() }
                row("arrow.counterclockwise", "Reset Timing") { actions.offsetReset() }
            }

            section("App") {
                row("gearshape", "Settings…", showSettings)
                row("power", "Quit EndLyrics", quit)
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(CoverBackdrop(url: theme.artworkURL, colors: theme.backgroundColors))
        .foregroundStyle(.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.nowPlaying ?? "Nothing playing")
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
            Text(model.providerName.map { "Lyrics from \($0)" } ?? "Waiting for lyrics")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            VStack(spacing: 2, content: content)
        }
    }

    private func row(_ symbol: String, _ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18)
                Text(title).font(.system(size: 12))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ symbol: String, _ title: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 18)
                Text(title).font(.system(size: 12))
                Spacer(minLength: 0)
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(on ? theme.accent : .white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.08)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
