import XCTest
@testable import LyricsCore

final class PositionClockTests: XCTestCase {
    func testPositionAdvancesWhilePlaying() {
        var clock = PositionClock()
        let start = Date(timeIntervalSince1970: 1_000)
        clock.resync(position: 10, playing: true, at: start)

        XCTAssertEqual(clock.position(at: start.addingTimeInterval(2.5)), 12.5, accuracy: 0.0001)
    }

    func testPositionIsFrozenWhilePaused() {
        var clock = PositionClock()
        let start = Date(timeIntervalSince1970: 1_000)
        clock.resync(position: 10, playing: false, at: start)

        XCTAssertEqual(clock.position(at: start.addingTimeInterval(30)), 10, accuracy: 0.0001)
    }

    func testResyncReplacesDriftedEstimate() {
        var clock = PositionClock()
        let start = Date(timeIntervalSince1970: 1_000)
        clock.resync(position: 10, playing: true, at: start)
        // Spotify reports 14 s after 5 s of local time, so the estimate had drifted to 15 s.
        clock.resync(position: 14, playing: true, at: start.addingTimeInterval(5))

        XCTAssertEqual(clock.position(at: start.addingTimeInterval(5)), 14, accuracy: 0.0001)
    }
}
