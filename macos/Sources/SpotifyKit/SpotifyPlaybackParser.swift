import Foundation

public enum SpotifyPlayerState: String, Equatable, Sendable {
    case playing
    case paused
    case stopped
}

/// What Spotify reports about the current track and playback position.
public struct PlaybackSnapshot: Equatable, Sendable {
    public let trackID: String
    public let title: String
    public let artist: String
    public let album: String
    /// Track length in seconds.
    public let duration: Double
    /// Current position in seconds.
    public let position: Double
    public let state: SpotifyPlayerState
    /// Cover art URL from Spotify's CDN. Used for colours only; the art itself is not shown.
    public let artworkURL: URL?
    public let shuffling: Bool
    public let repeating: Bool
    /// Spotify's output volume, 0...100.
    public let volume: Int

    public init(
        trackID: String,
        title: String,
        artist: String,
        album: String,
        duration: Double,
        position: Double,
        state: SpotifyPlayerState,
        artworkURL: URL? = nil,
        shuffling: Bool = false,
        repeating: Bool = false,
        volume: Int = 0
    ) {
        self.trackID = trackID
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.state = state
        self.artworkURL = artworkURL
        self.shuffling = shuffling
        self.repeating = repeating
        self.volume = volume
    }
}

/// Parses the single line printed by the AppleScript in `SpotifyScript`.
/// Fields are separated by the ASCII unit separator (0x1F), which titles never contain.
public enum SpotifyPlaybackParser {
    public static let separator = "\u{1F}"

    public static func parse(_ output: String) -> PlaybackSnapshot? {
        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }

        let fields = line.components(separatedBy: separator)
        guard fields.count == 11 else { return nil }

        let title = fields[1]
        // No current track (for example during an ad) has no title; there is nothing to look up.
        guard !title.isEmpty else { return nil }

        guard
            let durationMs = Double(fields[4]),
            let position = Double(fields[5]),
            let state = SpotifyPlayerState(rawValue: fields[6])
        else { return nil }

        return PlaybackSnapshot(
            trackID: fields[0],
            title: title,
            artist: fields[2],
            album: fields[3],
            // Spotify's AppleScript reports milliseconds; the dictionary wrongly says seconds.
            duration: durationMs / 1000,
            position: position,
            state: state,
            artworkURL: fields[7].isEmpty ? nil : URL(string: fields[7]),
            shuffling: fields[8] == "true",
            repeating: fields[9] == "true",
            volume: Int(fields[10]) ?? 0
        )
    }
}
