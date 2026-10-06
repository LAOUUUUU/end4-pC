import Foundation

/// A search result from LRCLIB, reduced to the fields the matcher needs.
public struct LyricsCandidate: Equatable, Sendable {
    public let trackName: String?
    public let artistName: String?
    public let syncedLyrics: String?

    public init(trackName: String?, artistName: String?, syncedLyrics: String?) {
        self.trackName = trackName
        self.artistName = artistName
        self.syncedLyrics = syncedLyrics
    }
}

/// Decides whether a LRCLIB result really is the track that is playing.
/// Mirrors `_is_match` in `scripts/lyrics/lyrics.py`, with one fix: an empty
/// name no longer matches every title (`"" in anything` is true in Python).
public enum LyricsMatcher {
    public static func matches(_ candidate: LyricsCandidate, title: String, artist: String) -> Bool {
        guard let synced = candidate.syncedLyrics, !synced.isEmpty else { return false }
        return nameMatches(candidate.trackName, query: title)
            && nameMatches(candidate.artistName, query: artist)
    }

    private static func nameMatches(_ name: String?, query: String) -> Bool {
        guard let name = name?.lowercased(), !name.isEmpty else { return false }
        let query = query.lowercased()

        if query.contains(name) || name.contains(query) { return true }
        // Any word longer than three characters from the query found in the name.
        return query.split(whereSeparator: \.isWhitespace).contains { word in
            word.count > 3 && name.contains(word)
        }
    }
}
