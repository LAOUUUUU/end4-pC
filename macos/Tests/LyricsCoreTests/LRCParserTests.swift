import XCTest
@testable import LyricsCore

final class LRCParserTests: XCTestCase {
    func testParsesTimestampedLines() {
        let lines = LRCParser.parse("[00:12.34]first line\n[01:02.50]second line")

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].time, 12.34, accuracy: 0.001)
        XCTAssertEqual(lines[0].text, "first line")
        XCTAssertEqual(lines[1].time, 62.5, accuracy: 0.001)
        XCTAssertEqual(lines[1].text, "second line")
    }

    func testSortsLinesByTime() {
        let lines = LRCParser.parse("[00:30.00]late\n[00:05.00]early")

        XCTAssertEqual(lines.map(\.text), ["early", "late"])
    }

    func testSkipsMalformedLinesAndBlankLines() {
        let input = "\n[bad]no time\n[00:10.00]kept\nplain text without tag"
        let lines = LRCParser.parse(input)

        XCTAssertEqual(lines.map(\.text), ["kept"])
    }

    func testKeepsEmptyTextLines() {
        // Instrumental gaps are empty lines; the widget renders them as a music note.
        let lines = LRCParser.parse("[00:01.00]")

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "")
    }

    func testTrimsWhitespaceAroundText() {
        let lines = LRCParser.parse("[00:01.00]   padded   ")

        XCTAssertEqual(lines[0].text, "padded")
    }
}
