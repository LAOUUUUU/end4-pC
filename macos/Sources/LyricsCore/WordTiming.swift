import Foundation

/// One word and the time window it is estimated to be sung in.
public struct WordSpan: Equatable, Sendable {
    public let word: String
    public let start: Double
    public let end: Double

    public init(word: String, start: Double, end: Double) {
        self.word = word
        self.start = start
        self.end = end
    }
}

/// Estimates word-by-word timing from line-level timestamps. LRCLIB gives only the time
/// each line starts, so each line's time is shared across its words by length.
public enum WordTiming {
    /// Seconds a final line is assumed to last, since it has no following line to end it.
    public static let lastLineSeconds = 4.0

    public static func spans(for text: String, start: Double, end: Double) -> [WordSpan] {
        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }

        let total = Double(words.reduce(0) { $0 + $1.count })
        let duration = max(0, end - start)
        var cursor = start
        return words.map { word in
            let share = duration * Double(word.count) / total
            defer { cursor += share }
            return WordSpan(word: word, start: cursor, end: cursor + share)
        }
    }

    /// Index of the word being sung at `position`: -1 before the first word, the last word after the line.
    public static func activeWordIndex(in spans: [WordSpan], at position: Double) -> Int {
        guard let first = spans.first, position >= first.start else { return -1 }
        var index = 0
        for (i, span) in spans.enumerated() where span.start <= position {
            index = i
        }
        return index
    }

    /// How far through the line playback is, 0...1 by time. Drives the smooth sweep of the karaoke highlight.
    public static func lineProgress(in spans: [WordSpan], at position: Double) -> Double {
        guard let first = spans.first, let last = spans.last, last.end > first.start else { return 0 }
        let fraction = (position - first.start) / (last.end - first.start)
        return min(1, max(0, fraction))
    }

    /// When the line at `index` ends: the next line's start, or a fixed guess for the last line.
    public static func lineEnd(of index: Int, in lines: [LyricLine]) -> Double {
        if index + 1 < lines.count {
            return lines[index + 1].time
        }
        return lines[index].time + lastLineSeconds
    }
}
