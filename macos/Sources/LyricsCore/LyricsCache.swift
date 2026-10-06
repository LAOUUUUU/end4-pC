import CryptoKit
import Foundation

/// Stores parsed lyrics on disk, one JSON file per track, so a replayed song
/// does not hit LRCLIB again. Keys are hashed to file names, so a track id can
/// never escape the cache directory.
public struct LyricsCache: Sendable {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// The default location, `~/Library/Caches/EndLyrics/lyrics`.
    public static var standard: LyricsCache {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return LyricsCache(directory: caches.appendingPathComponent("EndLyrics/lyrics", isDirectory: true))
    }

    public func lines(for key: String) -> [LyricLine]? {
        guard let data = try? Data(contentsOf: file(for: key)) else { return nil }
        return try? JSONDecoder().decode([StoredLine].self, from: data).map(\.lyricLine)
    }

    public func store(_ lines: [LyricLine], for key: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stored = lines.map(StoredLine.init)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: file(for: key), options: .atomic)
    }

    private func file(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("\(name).json")
    }

    private struct StoredLine: Codable {
        let time: Double
        let text: String

        init(_ line: LyricLine) {
            time = line.time
            text = line.text
        }

        var lyricLine: LyricLine { LyricLine(time: time, text: text) }
    }
}
