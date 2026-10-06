import Appearance
import LyricsCore
import SwiftUI

/// The standard panel: header, bars, seven lines of lyrics, progress, volume and controls.
/// Sizes and opacities of the lines match `modules/common/widgets/Lyrics.qml`.
struct LyricsView: View {
    @ObservedObject var model: LyricsModel
    /// Not observed here: the visualizer redraws itself 30 times a second, and this view must not.
    let visualizer: VisualizerModel
    @ObservedObject var theme: ThemeModel

    private static let lineSpacing: CGFloat = 6

    var body: some View {
        let settings = theme.settings
        VStack(alignment: .leading, spacing: Self.lineSpacing) {
            HStack(spacing: 8) {
                header
                expandButton
            }
            if !settings.compactMode {
                VisualizerView(model: visualizer, theme: theme)
            }
            LyricsStack(model: model, theme: theme, baseFont: 16, compact: settings.compactMode)
            if !settings.compactMode {
                ProgressBarView(fraction: model.progress, accent: theme.accent)
                VolumeSliderView(model: model, theme: theme)
                PlaybackControlsView(model: model, theme: theme)
            }
        }
        .padding(16)
        .frame(minWidth: 320, minHeight: 200, alignment: .topLeading)
        .background {
            ZStack {
                backdrop
                WindowDragHandle()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let nowPlaying = model.nowPlaying {
            Text(model.providerName.map { "\(nowPlaying) · \($0)" } ?? nowPlaying)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Spacer(minLength: 0)
        }
    }

    private var expandButton: some View {
        Button {
            model.expanded.toggle()
        } label: {
            Image(systemName: model.expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(model.expanded ? "Standard view" : "Now Playing view")
    }

    /// The cover, blurred, behind a gradient of its colours.
    private var backdrop: some View {
        CoverBackdrop(url: theme.artworkURL, colors: theme.backgroundColors, blur: theme.settings.backgroundBlur, imagePath: theme.settings.backgroundImagePath)
            .equatable()
    }
}

/// The lyrics as a scrolling column: the active line sits in the middle, and the lines above and
/// below slide up or down on a spring as the song moves on. Each line keeps its place in the song,
/// so it moves instead of being swapped out. Status messages replace the column when there are no lines.
struct LyricsStack: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    /// Font size of the active line, before the lyric-size setting.
    let baseFont: CGFloat
    var compact = false

    private var font: CGFloat { baseFont * CGFloat(theme.settings.lyricScale) }
    /// Height of one line slot. Taller than the text so wrapped lines and the sweep have room.
    private var rowHeight: CGFloat { font * 1.5 }

    var body: some View {
        Group {
            switch model.status {
            case .synced:
                scroller
            case .loading:
                ProgressView()
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .nothingPlaying:
                message("Nothing playing in Spotify")
            case .notFound:
                message("No synced lyrics for this track")
            case .error(let detail):
                message("Can't read Spotify. Allow control under Privacy & Security > Automation.\n\(detail)")
            }
        }
    }

    /// Only the lines near the active one are laid out. Each sits at its distance from the active line.
    @ViewBuilder
    private var scroller: some View {
        let active = model.activeIndex
        if active >= 0, model.lineCount > 0 {
            let first = max(0, active - 4)
            let last = min(model.lineCount - 1, active + 4)
            ZStack(alignment: .topLeading) {
                ForEach(Array(first...max(first, last)), id: \.self) { index in
                    row(index: index, active: active)
                }
            }
            // Only the slide between lines is animated here. The sweep has its own, shorter animation.
            .animation(.spring(response: 0.6, dampingFraction: 0.9), value: active)
            .frame(maxWidth: .infinity, minHeight: rowHeight * (compact ? 1 : 7), alignment: .topLeading)
            .clipped()
        } else {
            Color.clear
        }
    }

    private func row(index: Int, active: Int) -> some View {
        let distance = index - active
        let level = abs(distance)
        let isActive = distance == 0
        let visible = compact ? isActive : level <= 3
        let text = model.lineText(at: index)
        let display = text.isEmpty ? "♪" : text

        return Group {
            if isActive, !model.activeWords.isEmpty {
                KaraokeLine(text: display, progress: model.lineProgress, accent: theme.accent)
                    .font(.system(size: font, weight: .semibold))
            } else {
                Text(display)
                    .font(.system(size: size(distance: level)))
                    .foregroundStyle(.white)
            }
        }
        .opacity(visible ? opacity(distance: level) : 0)
        // One line per row. Long lines shrink to fit the width instead of being cut off.
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
        .scaleEffect(isActive ? 1 : 0.96, anchor: .leading)
        // Rows sit one slot apart, the active line in the middle slot (slot 3 of 0...6).
        .offset(y: CGFloat(compact ? 0 : distance + 3) * rowHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if theme.settings.clickToSeek, !text.isEmpty {
                model.seek(toLine: index)
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    /// Active line at `font`, then 0.94× and 0.75× for the next lines, 0.6× beyond.
    private func size(distance: Int) -> CGFloat {
        switch distance {
        case 0: return font
        case 1: return font * 0.94
        default: return font * 0.75
        }
    }

    /// Opacities from `Lyrics.qml`: 1.0, 0.6, 0.35, then 0.15.
    private func opacity(distance: Int) -> Double {
        switch distance {
        case 0: return 1.0
        case 1: return 0.6
        case 2: return 0.35
        default: return 0.15
        }
    }
}

/// The active line, filled in the accent colour from the left as it is sung.
/// The sweep follows the estimated line timing (see `WordTiming`), with a soft edge.
struct KaraokeLine: View {
    let text: String
    let progress: Double
    let accent: Color

    var body: some View {
        let edge = min(1, max(0, progress))
        Text(text)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .animation(.linear(duration: 0.12), value: edge)
            .foregroundStyle(LinearGradient(
                stops: [
                    .init(color: accent, location: max(0, edge - 0.04)),
                    .init(color: .white.opacity(0.45), location: min(1, edge + 0.04)),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
    }
}
