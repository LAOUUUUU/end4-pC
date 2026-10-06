import Appearance
import Foundation
import SpotifyKit

/// `EndLyrics --palette-check`: reads the playing track's artwork URL from Spotify, downloads the
/// cover, extracts its colours, writes them to `palette-check.txt` in the caches folder, and exits.
enum PaletteCheck {
    static func run() -> Never {
        Task {
            var report = "no playback"
            if case .success(let snapshot?) = await SpotifyBridge.read() {
                let url = snapshot.artworkURL
                var colors: [RGB] = []
                if let url {
                    colors = await ArtworkPalette.colors(from: url)
                }
                let formatted = colors.map { color in
                    String(format: "#%02X%02X%02X", Int(color.red * 255), Int(color.green * 255), Int(color.blue * 255))
                }
                report = "track=\(snapshot.title) artwork=\(url?.absoluteString ?? "none") colors=\(formatted)"
            }
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("EndLyrics", isDirectory: true)
            try? FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
            try? (report + "\n").write(to: caches.appendingPathComponent("palette-check.txt"), atomically: true, encoding: .utf8)
            exit(0)
        }
        dispatchMain()
    }
}
