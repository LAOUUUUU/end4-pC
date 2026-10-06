import XCTest
@testable import SpotifyKit

final class SpotifyVolumeTests: XCTestCase {
    func testSetsSoundVolume() {
        XCTAssertTrue(SpotifyVolume.script(to: 40).contains("set sound volume to 40"))
    }

    func testClampsToZeroThroughHundred() {
        XCTAssertTrue(SpotifyVolume.script(to: 150).contains("set sound volume to 100"))
        XCTAssertTrue(SpotifyVolume.script(to: -3).contains("set sound volume to 0"))
    }

    func testIsGuardedSoItNeverLaunchesSpotify() {
        XCTAssertTrue(SpotifyVolume.script(to: 50).contains("if application \"Spotify\" is running"))
    }
}
