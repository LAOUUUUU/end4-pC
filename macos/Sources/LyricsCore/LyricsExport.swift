import Foundation

/// Writes lyrics as `.lrc` (time-synced) or `.txt` (plain), the two outputs Manzana produces.
public enum LyricsExport {
    /// LRC text. Timestamps are `[mm:ss.cc]`, or `[mm:ss.mmm]` with `millisecondPrecision`.
    public static func lrc(
        _ lines: [LyricLine],
        title: String? = nil,
        artist: String? = nil,
        millisecondPrecision: Bool = false
    ) -> String {
        var out = ""
        if let title { out += "[ti:\(title)]\n" }
        if let artist { out += "[ar:\(artist)]\n" }
        for line in lines {
            out += "[\(timestamp(line.time, millisecondPrecision: millisecondPrecision))]\(line.text)\n"
        }
        return out
    }

    /// Plain text, one lyric per line, without timestamps.
    public static func txt(_ lines: [LyricLine]) -> String {
        lines.map { $0.text + "\n" }.joined()
    }

    /// A file name from the track, with characters that are unsafe in file names replaced.
    public static func fileName(title: String, artist: String, extension ext: String) -> String {
        let unsafe = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let clean: (String) -> String = { text in
            String(text.unicodeScalars.map { unsafe.contains($0) ? "-" : Character($0) })
        }
        return "\(clean(artist)) - \(clean(title)).\(ext)"
    }

    private static func timestamp(_ seconds: Double, millisecondPrecision: Bool) -> String {
        let total = Int((max(0, seconds) * 1000).rounded())
        let minutes = total / 60_000
        let secs = (total % 60_000) / 1000
        let fraction = total % 1000
        if millisecondPrecision {
            return String(format: "%02d:%02d.%03d", minutes, secs, fraction)
        }
        return String(format: "%02d:%02d.%02d", minutes, secs, fraction / 10)
    }
}
