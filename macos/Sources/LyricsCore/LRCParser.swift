import Foundation

/// One timed line of synced lyrics.
public struct LyricLine: Equatable, Sendable {
    /// Seconds from the start of the track.
    public let time: Double
    /// Lyric text. Empty for instrumental gaps.
    public let text: String

    public init(time: Double, text: String) {
        self.time = time
        self.text = text
    }
}

/// Parses LRC synced-lyrics text (`[mm:ss.xx] line`), the format LRCLIB returns.
/// Mirrors `_parse_lrc` in `scripts/lyrics/lyrics.py`.
public enum LRCParser {
    private static let pattern = try! NSRegularExpression(
        pattern: #"^\[(\d+):(\d+(?:\.\d+)?)\](.*)$"#
    )

    public static func parse(_ text: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard let match = pattern.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
            ) else { continue }

            guard
                let minutes = Double(substring(trimmed, match.range(at: 1))),
                let seconds = Double(substring(trimmed, match.range(at: 2)))
            else { continue }

            let body = substring(trimmed, match.range(at: 3))
                .trimmingCharacters(in: .whitespaces)
            lines.append(LyricLine(time: minutes * 60 + seconds, text: body))
        }
        return lines.sorted { $0.time < $1.time }
    }

    private static func substring(_ source: String, _ range: NSRange) -> String {
        guard let swiftRange = Range(range, in: source) else { return "" }
        return String(source[swiftRange])
    }
}
