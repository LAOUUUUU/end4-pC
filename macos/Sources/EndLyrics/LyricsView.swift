import LyricsCore
import SwiftUI

/// Seven-line lyrics display. Sizes and opacities match `modules/common/widgets/Lyrics.qml`:
/// the active line is largest and fully opaque, its neighbours step down.
struct LyricsView: View {
    @ObservedObject var model: LyricsModel

    private static let lineSpacing: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: Self.lineSpacing) {
            switch model.status {
            case .synced:
                ForEach(Array(model.slots.enumerated()), id: \.offset) { index, text in
                    Text(text)
                        .font(.system(size: Self.fontSize(distance: Self.distance(index))))
                        .opacity(Self.opacity(distance: Self.distance(index)))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(16)
        .frame(minWidth: 320, minHeight: 200, alignment: .topLeading)
        // A dark backdrop keeps the white text readable on light wallpapers.
        // The shell widget sits on the wallpaper with no backdrop, so this is a deliberate difference.
        .background(RoundedRectangle(cornerRadius: 14).fill(.black.opacity(0.55)))
        .animation(.easeOut(duration: 0.25), value: model.activeIndex)
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
