import XCTest
@testable import SpotifyKit

/// Reads the real Spotify desktop app. Skipped unless `ENDLYRICS_LIVE_TESTS=1`.
/// Read-only: it never sends play, pause or skip commands.
final class SpotifyBridgeLiveTests: XCTestCase {
    func testReadsCurrentPlaybackFromRunningSpotify() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ENDLYRICS_LIVE_TESTS"] == "1")

        let result = await SpotifyBridge.read()

        // A denied Automation request must fail here, not look like "nothing playing".
        let snapshot = try result.get()
        print("LIVE snapshot: \(String(describing: snapshot))")
    }
}
