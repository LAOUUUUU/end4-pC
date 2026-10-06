import Appearance
import LyricsCore
import SwiftUI

/// The standard panel: header, bars, seven lines of lyrics, progress, volume and controls.
/// Sizes and opacities of the lines match `modules/common/widgets/Lyrics.qml`.
struct LyricsView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var visualizer: VisualizerModel
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
        .background(backdrop)
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
    }
}

/// The seven visible lines, or the status message in their place. Line changes animate.
struct LyricsStack: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var theme: ThemeModel
    /// Font size of the active line, before the lyric-size setting. The other lines scale from it.
    let baseFont: CGFloat
    var compact = false

    private var font: CGFloat { baseFont * CGFloat(theme.settings.lyricScale) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch model.status {
            case .synced:
                ForEach(Array(model.slots.enumerated()), id: \.offset) { index, text in
                    lyricLine(index: index, text: text)
                }
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
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.activeIndex)
    }

    @ViewBuilder
    private func lyricLine(index: Int, text: String) -> some View {
        let distance = abs(index - LyricsTimeline.before)
        if !compact || distance == 0 {
            Group {
                if index == LyricsTimeline.before, !model.activeWords.isEmpty {
                    KaraokeLine(words: model.activeWords, highlighted: model.highlightedWord, accent: theme.accent)
                        .font(.system(size: font))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text(text)
                        .font(.system(size: size(distance: distance)))
                        .opacity(opacity(distance: distance))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .id("\(index)-\(text)")
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if theme.settings.clickToSeek, !text.isEmpty {
                    model.seek(toSlot: index)
                }
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

    /// Active line at `font`, then 0.94× and 0.75× for the next lines, 0.6× beyond. The standard panel's 16/15/12 pt.
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

/// The active line with the sung word in the accent colour and the rest dimmed.
/// Word timing is estimated from line timestamps (see `WordTiming`), not measured per word.
struct KaraokeLine: View {
    let words: [WordSpan]
    let highlighted: Int
    let accent: Color

    var body: some View {
        words.enumerated().reduce(Text("")) { line, item in
            let separator = item.offset == 0 ? "" : " "
            let color: Color = item.offset <= highlighted ? accent : .white.opacity(0.45)
            return line + Text(separator + item.element.word).foregroundColor(color)
        }
    }
}
