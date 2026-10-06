import XCTest
@testable import LyricsCore

final class LyricsTimelineTests: XCTestCase {
    private let lines = [
        LyricLine(time: 5, text: "one"),
        LyricLine(time: 10, text: "two"),
        LyricLine(time: 15, text: ""),
        LyricLine(time: 20, text: "four"),
    ]

    func testActiveIndexIsMinusOneBeforeFirstLine() {
        XCTAssertEqual(LyricsTimeline.activeIndex(at: 2, in: lines), -1)
    }

    func testActiveIndexOnExactTimestamp() {
        XCTAssertEqual(LyricsTimeline.activeIndex(at: 10, in: lines), 1)
    }

    func testActiveIndexBetweenTimestampsIsEarlierLine() {
        XCTAssertEqual(LyricsTimeline.activeIndex(at: 12.5, in: lines), 1)
    }

    func testActiveIndexAfterLastLineIsLastLine() {
        XCTAssertEqual(LyricsTimeline.activeIndex(at: 999, in: lines), 3)
    }

    func testActiveIndexOnEmptyLyricsIsMinusOne() {
        XCTAssertEqual(LyricsTimeline.activeIndex(at: 5, in: []), -1)
    }

    func testSlotsPutActiveLineInMiddleSlotWithThreeLinesBefore() {
        // Active line "four" (index 3) sits in slot 3; slots 0–2 hold the three lines before it.
        let slots = LyricsTimeline.slots(activeIndex: 3, in: lines)

        XCTAssertEqual(slots, ["one", "two", "♪", "four", "", "", ""])
    }

    func testSlotsBeforeAnyLineAreAllEmpty() {
        XCTAssertEqual(
            LyricsTimeline.slots(activeIndex: -1, in: lines),
            ["", "", "", "", "", "", ""]
        )
    }

    func testSlotsRenderEmptyLyricLinesAsMusicNote() {
        // Index 2 is the empty line at 15 s; it must show the note, not a blank slot.
        let slots = LyricsTimeline.slots(activeIndex: 2, in: lines)

        XCTAssertEqual(slots[LyricsTimeline.before], "♪")
    }
}
