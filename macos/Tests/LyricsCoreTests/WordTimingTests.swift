import XCTest
@testable import LyricsCore

final class WordTimingTests: XCTestCase {
    func testSplitsLineTimeInProportionToWordLength() {
        // "a" has 1 character, "bb" has 2, so "bb" gets two thirds of the 3-second line.
        let spans = WordTiming.spans(for: "a bb", start: 0, end: 3)

        XCTAssertEqual(spans.map(\.word), ["a", "bb"])
        XCTAssertEqual(spans[0].start, 0, accuracy: 0.0001)
        XCTAssertEqual(spans[0].end, 1, accuracy: 0.0001)
        XCTAssertEqual(spans[1].start, 1, accuracy: 0.0001)
        XCTAssertEqual(spans[1].end, 3, accuracy: 0.0001)
    }

    func testSingleWordGetsTheWholeLine() {
        let spans = WordTiming.spans(for: "hello", start: 10, end: 12)

        XCTAssertEqual(spans, [WordSpan(word: "hello", start: 10, end: 12)])
    }

    func testBlankTextGivesNoSpans() {
        XCTAssertEqual(WordTiming.spans(for: "   ", start: 0, end: 2), [])
        XCTAssertEqual(WordTiming.spans(for: "", start: 0, end: 2), [])
    }

    func testActiveWordFollowsPosition() {
        let spans = WordTiming.spans(for: "a bb", start: 0, end: 3)

        XCTAssertEqual(WordTiming.activeWordIndex(in: spans, at: 0.5), 0)
        XCTAssertEqual(WordTiming.activeWordIndex(in: spans, at: 1.0), 1)
        XCTAssertEqual(WordTiming.activeWordIndex(in: spans, at: 2.9), 1)
    }

    func testActiveWordIsLastWordAfterTheLine() {
        let spans = WordTiming.spans(for: "a bb", start: 0, end: 3)

        XCTAssertEqual(WordTiming.activeWordIndex(in: spans, at: 9), 1)
    }

    func testNoActiveWordBeforeTheLineStarts() {
        let spans = WordTiming.spans(for: "a bb", start: 5, end: 8)

        XCTAssertEqual(WordTiming.activeWordIndex(in: spans, at: 2), -1)
    }

    func testLineEndIsNextLineStart() {
        let lines = [LyricLine(time: 1, text: "a"), LyricLine(time: 4, text: "b")]

        XCTAssertEqual(WordTiming.lineEnd(of: 0, in: lines), 4, accuracy: 0.0001)
    }

    func testLastLineEndsAfterAFixedGuess() {
        let lines = [LyricLine(time: 1, text: "a"), LyricLine(time: 4, text: "b")]

        XCTAssertEqual(WordTiming.lineEnd(of: 1, in: lines), 8, accuracy: 0.0001)
    }
}
