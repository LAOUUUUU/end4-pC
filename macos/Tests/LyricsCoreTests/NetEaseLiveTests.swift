import XCTest
@testable import LyricsCore

/// Calls the real NetEase API. Skipped unless `ENDLYRICS_LIVE_TESTS=1`.
final class NetEaseLiveTests: XCTestCase {
    func testFindsLyricsLRCLIBDoesNotHave() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ENDLYRICS_LIVE_TESTS"] == "1")

        let lines = await NetEaseProvider().fetch(title: "я люблю тебя", artist: "emosl4t696", duration: 86.7)

        XCTAssertGreaterThan(try XCTUnwrap(lines).count, 3)
    }
}
