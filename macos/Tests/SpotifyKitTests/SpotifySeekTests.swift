import XCTest
@testable import SpotifyKit

final class SpotifySeekTests: XCTestCase {
    func testSetsPlayerPositionInSeconds() {
        XCTAssertTrue(SpotifySeek.script(to: 42.5).contains("set player position to 42.5"))
    }

    func testNegativeTimeSeeksToStart() {
        XCTAssertTrue(SpotifySeek.script(to: -4).contains("set player position to 0"))
    }

    func testIsGuardedSoItNeverLaunchesSpotify() {
        XCTAssertTrue(SpotifySeek.script(to: 1).contains("if application \"Spotify\" is running"))
    }
}
