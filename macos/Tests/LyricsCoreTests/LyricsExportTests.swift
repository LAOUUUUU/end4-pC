import XCTest
@testable import LyricsCore

final class LyricsExportTests: XCTestCase {
    private let lines = [
        LyricLine(time: 12.345, text: "first line"),
        LyricLine(time: 65.5, text: ""),
        LyricLine(time: 3723.07, text: "late line"),
    ]

    func testLRCUsesCentisecondsByDefault() {
        let text = LyricsExport.lrc(lines)

        XCTAssertEqual(text, "[00:12.34]first line\n[01:05.50]\n[62:03.07]late line\n")
    }

    func testLRCMillisecondPrecisionKeepsThreeDigits() {
        let text = LyricsExport.lrc(lines, millisecondPrecision: true)

        XCTAssertTrue(text.hasPrefix("[00:12.345]first line\n"))
        XCTAssertTrue(text.contains("[01:05.500]\n"))
    }

    func testLRCWritesMetadataHeadersFirst() {
        let text = LyricsExport.lrc(lines, title: "Blinding Lights", artist: "The Weeknd")

        XCTAssertTrue(text.hasPrefix("[ti:Blinding Lights]\n[ar:The Weeknd]\n[00:12.34]first line\n"))
    }

    func testTXTHasOneLinePerLyricWithoutTimestamps() {
        XCTAssertEqual(LyricsExport.txt(lines), "first line\n\nlate line\n")
    }

    func testFileNameIsSafeForTheFilesystem() {
        XCTAssertEqual(
            LyricsExport.fileName(title: "Back: In Black", artist: "AC/DC", extension: "lrc"),
            "AC-DC - Back- In Black.lrc"
        )
    }
}
