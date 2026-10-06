import XCTest
@testable import LyricsCore

/// Hits the real LRCLIB API. Skipped unless `ENDLYRICS_LIVE_TESTS=1`, so the normal
/// test run stays offline and deterministic.
final class LRCLibLiveTests: XCTestCase {
    func testFetchesSyncedLyricsForKnownTrack() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ENDLYRICS_LIVE_TESTS"] == "1")

        let lines = await LRCLibClient.fetchSyncedLyrics(
            title: "Blinding Lights",
            artist: "The Weeknd",
            duration: 200
        )

        let result = try XCTUnwrap(lines)
        XCTAssertGreaterThan(result.count, 10)
        XCTAssertEqual(result, result.sorted { $0.time < $1.time }, "lines must be in time order")
    }

    func testReturnsNilForTrackWithNoLyrics() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ENDLYRICS_LIVE_TESTS"] == "1")

        let lines = await LRCLibClient.fetchSyncedLyrics(
            title: "zzz-no-such-track-endlyrics",
            artist: "nobody-endlyrics",
            duration: 1
        )

        XCTAssertNil(lines)
    }
}
