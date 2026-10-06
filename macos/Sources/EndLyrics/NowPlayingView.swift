import Appearance
import SwiftUI

/// Large now-playing layout: cover art, the visualizer, big animated lyrics, and the controls.
/// The cover is shown with the attribution and link back to Spotify that its developer policy requires.
struct NowPlayingView: View {
    @ObservedObject var model: LyricsModel
    let visualizer: VisualizerModel
    @ObservedObject var theme: ThemeModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                // Without this, the Now Playing layout had no button to return to the standard size.
                Button {
                    model.expanded.toggle()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 26, height: 22)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Standard view (⌘E)")
            }
            HStack(spacing: 14) {
                AsyncImage(url: model.artworkURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.1))
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.nowPlaying ?? "Nothing playing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("Cover art from Spotify")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                    if let link = model.spotifyTrackURL {
                        Link("Open in Spotify", destination: link)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                Spacer(minLength: 0)
            }

            VisualizerView(model: visualizer, theme: theme)
            ProgressBarView(fraction: model.progress, accent: theme.accent) { model.seek(toFraction: $0) }
            LyricsStack(model: model, theme: theme, baseFont: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            VolumeSliderView(model: model, theme: theme)
            PlaybackControlsView(model: model, theme: theme)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Without a backdrop, the white text sits on whatever is behind the panel and disappears.
        .background(CoverBackdrop(url: model.artworkURL, colors: theme.backgroundColors, blur: theme.settings.backgroundBlur, imagePath: theme.settings.backgroundImagePath)
                .equatable())
    }
}

/// The window background: a custom image if one is set, otherwise the cover, blurred behind a gradient.
/// The cover is only used as a blurred backdrop, so it cannot be read off the panel.
struct CoverBackdrop: View, Equatable {
    let url: URL?
    let colors: [Color]
    var blur: Double = 40
    var imagePath: String?

    /// Equal inputs mean the same picture, so SwiftUI can skip redrawing the blur.
    static func == (lhs: CoverBackdrop, rhs: CoverBackdrop) -> Bool {
        lhs.url == rhs.url && lhs.colors == rhs.colors && lhs.blur == rhs.blur && lhs.imagePath == rhs.imagePath
    }

    var body: some View {
        ZStack {
            if let imagePath, let image = BackgroundImageCache.image(at: imagePath) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: blur)
                    .opacity(0.6)
            } else {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill().blur(radius: blur).opacity(0.5)
                } placeholder: {
                    Color.clear
                }
            }
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Decoded background images, so a redraw does not decode the file again.
enum BackgroundImageCache {
    private static let cache = NSCache<NSString, NSImage>()

    static func image(at path: String) -> NSImage? {
        if let cached = cache.object(forKey: path as NSString) { return cached }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: path as NSString)
        return image
    }
}
