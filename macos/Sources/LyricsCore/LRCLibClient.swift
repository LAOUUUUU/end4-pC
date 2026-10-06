import Foundation

/// Fetches synced lyrics from the public LRCLIB API (https://lrclib.net).
/// Mirrors `fetch_lrclib` in `scripts/lyrics/lyrics.py`: three lookups in order,
/// first result that matches the track and has synced lyrics wins.
public enum LRCLibClient {
    private static let base = "https://lrclib.net/api"

    /// RFC 3986 unreserved characters, so titles cannot inject query parameters.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// The three lookups, in the order the Python version tries them.
    public static func lookupURLs(title: String, artist: String, duration: Double) -> [URL] {
        let t = encode(title)
        let a = encode(artist)
        let q = encode("\(title) \(artist)")
        return [
            "\(base)/get?track_name=\(t)&artist_name=\(a)&duration=\(Int(duration))",
            "\(base)/search?track_name=\(t)&artist_name=\(a)",
            "\(base)/search?q=\(q)",
        ].compactMap(URL.init(string:))
    }

    /// Decodes either a single `get` object or a `search` array.
    public static func decodeCandidates(_ data: Data) throws -> [LyricsCandidate] {
        let decoder = JSONDecoder()
        if let list = try? decoder.decode([Record].self, from: data) {
            return list.map(\.candidate)
        }
        return [try decoder.decode(Record.self, from: data).candidate]
    }

    /// Returns the first matching track's synced lyrics, or nil if no lookup matched.
    /// A failed lookup is skipped, as in the Python version.
    public static func fetchSyncedLyrics(
        title: String,
        artist: String,
        duration: Double,
        session: URLSession = .shared
    ) async -> [LyricLine]? {
        for url in lookupURLs(title: title, artist: artist, duration: duration) {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 15
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

                let candidates = try decodeCandidates(data)
                guard let match = candidates.first(where: {
                    LyricsMatcher.matches($0, title: title, artist: artist)
                }), let synced = match.syncedLyrics else { continue }

                let lines = LRCParser.parse(synced)
                if !lines.isEmpty { return lines }
            } catch {
                continue
            }
        }
        return nil
    }

    private static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
    }

    private struct Record: Decodable {
        let trackName: String?
        let artistName: String?
        let syncedLyrics: String?

        var candidate: LyricsCandidate {
            LyricsCandidate(trackName: trackName, artistName: artistName, syncedLyrics: syncedLyrics)
        }
    }
}
