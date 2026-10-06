import Foundation

/// NetEase Cloud Music as a lyrics provider. Searches by title and artist, keeps the
/// song whose length matches, then parses its LRC lyric. Credit lines are removed.
public struct NetEaseProvider: LyricsProvider {
    public let name = "NetEase"

    public init() {}

    public func fetch(title: String, artist: String, duration: Double) async -> [LyricLine]? {
        guard let searchURL = NetEaseClient.searchURL(query: "\(title) \(artist)"),
              let searchData = await Self.get(searchURL),
              let songs = try? NetEaseClient.decodeSongs(searchData),
              let song = NetEaseClient.bestMatch(in: songs, title: title, artist: artist, duration: duration),
              let lyricURL = NetEaseClient.lyricURL(songID: song.id),
              let lyricData = await Self.get(lyricURL),
              let lrc = try? NetEaseClient.decodeLRC(lyricData)
        else { return nil }

        let lines = NetEaseClient.removingCredits(LRCParser.parse(lrc))
        return lines.isEmpty ? nil : lines
    }

    /// One GET request. NetEase rejects requests without these headers.
    private static func get(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("https://music.163.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            return nil
        }
    }
}
