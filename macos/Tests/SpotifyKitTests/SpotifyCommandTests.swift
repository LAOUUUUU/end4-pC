import XCTest
@testable import SpotifyKit

final class SpotifyCommandTests: XCTestCase {
    func testPlayPauseSendsPlaypause() {
        XCTAssertTrue(SpotifyCommand.playPause.script.contains("tell application \"Spotify\" to playpause"))
    }

    func testNextAndPreviousSendTrackCommands() {
        XCTAssertTrue(SpotifyCommand.next.script.contains("next track"))
        XCTAssertTrue(SpotifyCommand.previous.script.contains("previous track"))
    }

    func testEveryCommandIsGuardedSoItNeverLaunchesSpotify() {
        for command in SpotifyCommand.allCases {
            XCTAssertTrue(command.script.contains("if application \"Spotify\" is running"), "\(command)")
            XCTAssertFalse(command.script.contains("activate"), "\(command) must not bring Spotify forward")
        }
    }
}
