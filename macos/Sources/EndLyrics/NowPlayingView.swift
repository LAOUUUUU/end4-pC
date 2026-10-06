import Appearance
import SwiftUI

/// Large now-playing layout: cover art, the visualizer, big animated lyrics, and the controls.
/// The cover is shown with the attribution and link back to Spotify that its developer policy requires.
struct NowPlayingView: View {
    @ObservedObject var model: LyricsModel
    @ObservedObject var visualizer: VisualizerModel
    @ObservedObject var theme: ThemeModel

    var body: some View {
        VStack(spacing: 12) {
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
            ProgressBarView(fraction: model.progress, accent: theme.accent)
            LyricsStack(model: model, theme: theme, font: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            VolumeSliderView(model: model, theme: theme)
            PlaybackControlsView(model: model, theme: theme)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Without a backdrop, the white text sits on whatever is behind the panel and disappears.
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: theme.backgroundColors, startPoint: .top, endPoint: .bottom))
        )
    }
}
