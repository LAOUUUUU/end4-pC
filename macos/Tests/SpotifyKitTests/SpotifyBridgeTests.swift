import XCTest
@testable import SpotifyKit

final class SpotifyBridgeTests: XCTestCase {
    private let sep = "\u{1F}"

    func testSuccessfulRunWithTrackReturnsSnapshot() throws {
        let stdout = ["spotify:track:x", "Song", "Artist", "Album", "180000", "10", "playing", "https://i.scdn.co/image/x"]
            .joined(separator: sep) + "\n"

        let result = SpotifyBridge.interpret(exitCode: 0, stdout: stdout, stderr: "")

        XCTAssertEqual(try result.get()?.title, "Song")
    }

    func testSuccessfulRunWithNothingPlayingReturnsNil() throws {
        XCTAssertNil(try SpotifyBridge.interpret(exitCode: 0, stdout: "\n", stderr: "").get())
    }

    func testNonZeroExitIsAnErrorNotNothingPlaying() {
        // osascript exits non-zero when macOS denies automation access (error -1743).
        let result = SpotifyBridge.interpret(
            exitCode: 1,
            stdout: "",
            stderr: "execution error: Not authorized to send Apple events to Spotify. (-1743)"
        )

        switch result {
        case .success:
            XCTFail("a denied automation request must not look like an idle player")
        case .failure(let error):
            XCTAssertEqual(error, .scriptFailed("execution error: Not authorized to send Apple events to Spotify. (-1743)"))
        }
    }
}
