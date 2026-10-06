import Appearance
import LyricsCore
import SwiftUI

/// Seven-line lyrics display. Sizes and opacities match `modules/common/widgets/Lyrics.qml`:
/// the active line is largest and fully opaque, its neighbours step down.
struct LyricsView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var visualizer: VisualizerModel
    @ObservedObject var theme: ThemeModel

    private static let lineSpacing: CGFloat = 6

    var body: some View {
        let settings = theme.settings
        VStack(alignment: .leading, spacing: Self.lineSpacing) {
            if let nowPlaying = model.nowPlaying {
                Text(model.providerName.map { "\(nowPlaying) · \($0)" } ?? nowPlaying)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !settings.compactMode {
                VisualizerView(model: visualizer, theme: theme)
            }
            switch model.status {
            case .synced:
                ForEach(Array(model.slots.enumerated()), id: \.offset) { index, text in
                    lyricLine(index: index, text: text, settings: settings)
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
            if !settings.compactMode {
                ProgressBarView(fraction: model.progress, accent: theme.accent)
                PlaybackControlsView(model: model, theme: theme)
            }
        }
        .padding(16)
        .frame(minWidth: 320, minHeight: 200, alignment: .topLeading)
        .background(backdrop)
        .animation(.easeOut(duration: 0.25), value: model.activeIndex)
    }

    @ViewBuilder
    private func lyricLine(index: Int, text: String, settings: AppSettings) -> some View {
        let distance = Self.distance(index)
        if !settings.compactMode || distance == 0 {
            Group {
                if index == LyricsTimeline.before, !model.activeWords.isEmpty {
                    KaraokeLine(words: model.activeWords, highlighted: model.highlightedWord, accent: theme.accent)
                        .font(.system(size: Self.fontSize(distance: 0)))
                } else {
                    Text(text)
                        .font(.system(size: Self.fontSize(distance: distance)))
                        .opacity(Self.opacity(distance: distance))
                        .foregroundStyle(.white)
                }
            }
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if settings.clickToSeek, !text.isEmpty {
                    model.seek(toSlot: index)
                }
            }
        }
    }

    /// Dark glass, with a faint wash of the accent colour at the top.
    private var backdrop: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.black.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [theme.accent.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
            )
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    /// Distance from the active slot: 0 for the active line, then 1, 2, 3.
    private static func distance(_ index: Int) -> Int {
        abs(index - LyricsTimeline.before)
    }

    /// 16 pt active, 15 pt next, 12 pt beyond, as in `Appearance.font.pixelSize`.
    private static func fontSize(distance: Int) -> CGFloat {
        switch distance {
        case 0: return 16
        case 1: return 15
        default: return 12
        }
    }

    /// Opacities from `Lyrics.qml`: 1.0, 0.6, 0.35, then 0.15.
    private static func opacity(distance: Int) -> Double {
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
