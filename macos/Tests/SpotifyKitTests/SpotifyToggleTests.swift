import XCTest
@testable import SpotifyKit

final class SpotifyToggleTests: XCTestCase {
    func testShuffleScriptSetsShuffling() {
        XCTAssertTrue(SpotifyToggle.shuffle(on: true).contains("set shuffling to true"))
        XCTAssertTrue(SpotifyToggle.shuffle(on: false).contains("set shuffling to false"))
    }

    func testRepeatScriptSetsRepeating() {
        XCTAssertTrue(SpotifyToggle.repeating(on: true).contains("set repeating to true"))
    }

    func testToggleScriptsAreGuarded() {
        XCTAssertTrue(SpotifyToggle.shuffle(on: true).contains("if application \"Spotify\" is running"))
        XCTAssertTrue(SpotifyToggle.repeating(on: true).contains("if application \"Spotify\" is running"))
    }
}
