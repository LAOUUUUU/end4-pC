import Foundation

/// A song from NetEase Cloud Music's search results.
public struct NetEaseSong: Equatable, Sendable {
    public let id: Int
    public let name: String
    public let artists: [String]
    public let durationSeconds: Double

    public init(id: Int, name: String, artists: [String], durationSeconds: Double) {
        self.id = id
        self.name = name
        self.artists = artists
        self.durationSeconds = durationSeconds
    }
}

/// Lyrics from NetEase Cloud Music's web API (music.163.com).
/// This API is undocumented and unofficial. It can change or stop working without notice.
/// Only public GET endpoints are used, one search and one lyric request per track.
public enum NetEaseClient {
    private static let base = "https://music.163.com/api"
    /// Allowed difference between Spotify's track length and NetEase's, in seconds.
    static let durationToleranceSeconds = 3.0

    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// Lines NetEase adds for credits, such as "作词 : ..." (lyricist) or "作曲 : ..." (composer).
    private static let creditPattern = try! NSRegularExpression(
        pattern: #"^(作词|作曲|编曲|制作人|混音|监制|和声|录音|母带|词|曲|制作)\s*[:：]"#
    )

    public static func searchURL(query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: unreserved) ?? query
        return URL(string: "\(base)/search/get?s=\(encoded)&type=1&limit=5")
    }

    public static func lyricURL(songID: Int) -> URL? {
        URL(string: "\(base)/song/lyric?id=\(songID)&lv=1&kv=1&tv=-1")
    }

    public static func decodeSongs(_ data: Data) throws -> [NetEaseSong] {
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return (response.result?.songs ?? []).map { song in
            NetEaseSong(
                id: song.id,
                name: song.name,
                artists: song.artists.map(\.name),
                durationSeconds: Double(song.duration) / 1000
            )
        }
    }

    /// The LRC text, or nil when the song has no lyric.
    public static func decodeLRC(_ data: Data) throws -> String? {
        let response = try JSONDecoder().decode(LyricResponse.self, from: data)
        guard let lyric = response.lrc?.lyric, !lyric.isEmpty else { return nil }
        return lyric
    }

    public static func removingCredits(_ lines: [LyricLine]) -> [LyricLine] {
        lines.filter { line in
            let range = NSRange(line.text.startIndex..., in: line.text)
            return creditPattern.firstMatch(in: line.text, range: range) == nil
        }
    }

    /// The search hit whose title and artist match and whose length is within tolerance.
    public static func bestMatch(in songs: [NetEaseSong], title: String, artist: String, duration: Double) -> NetEaseSong? {
        songs.first { song in
            let candidate = LyricsCandidate(
                trackName: song.name,
                artistName: song.artists.joined(separator: ", "),
                syncedLyrics: "x"
            )
            guard LyricsMatcher.matches(candidate, title: title, artist: artist) else { return false }
            return duration <= 0 || abs(song.durationSeconds - duration) <= durationToleranceSeconds
        }
    }

    private struct SearchResponse: Decodable {
        struct Result: Decodable { let songs: [Song]? }
        struct Song: Decodable {
            let id: Int
            let name: String
            let artists: [Artist]
            let duration: Int
        }
        struct Artist: Decodable { let name: String }
        let result: Result?
    }

    private struct LyricResponse: Decodable {
        struct Lrc: Decodable { let lyric: String? }
        let lrc: Lrc?
    }
}
