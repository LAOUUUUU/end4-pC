import Foundation

/// Picks the active line and the seven visible slots for the lyrics window.
/// Mirrors `indexAt` and `buildSlots` in `services/LyricsService.qml`.
public enum LyricsTimeline {
    /// Lines shown above the active line.
    public static let before = 3
    /// Total slots: `before` lines, the active line, then `before` lines after it.
    public static let total = 7

    /// Index of the last line whose time is at or before `position`, or -1 if none.
    /// Binary search, as in the widget.
    public static func activeIndex(at position: Double, in lines: [LyricLine]) -> Int {
        var low = 0
        var high = lines.count - 1
        var result = -1
        while low <= high {
            let mid = (low + high) >> 1
            if lines[mid].time <= position {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    /// Text for each slot. Empty instrumental lines show a note. Slots outside the
    /// lyrics are blank. Before the first line (`activeIndex` -1) every slot is blank.
    public static func slots(activeIndex: Int, in lines: [LyricLine]) -> [String] {
        guard activeIndex >= 0 else { return Array(repeating: "", count: total) }
        return (0..<total).map { slot in
            let lineIndex = activeIndex - before + slot
            guard lineIndex >= 0, lineIndex < lines.count else { return "" }
            let text = lines[lineIndex].text
            return text.isEmpty ? "♪" : text
        }
    }
}
