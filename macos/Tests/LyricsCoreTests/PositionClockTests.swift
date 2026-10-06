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

final class PositionClockLatencyTests: XCTestCase {
    func testReportedPositionIsAdvancedByHalfTheRoundTrip() {
        var clock = PositionClock()
        let now = Date(timeIntervalSince1970: 1_000)
        // Spotify said 10 s, the reply took 0.4 s, so the position is about 10.2 s when it arrived.
        clock.resync(position: 10, playing: true, at: now, latency: 0.4)

        XCTAssertEqual(clock.position(at: now), 10.2, accuracy: 0.001)
    }

    func testSmallCorrectionsDoNotSnapTheLyrics() {
        var clock = PositionClock()
        let start = Date(timeIntervalSince1970: 1_000)
        clock.resync(position: 12, playing: true, at: start, latency: 0)

        // A poll reports 12.1 s when the clock predicts 12.0 s: jitter, so keep the prediction.
        let later = start.addingTimeInterval(0)
        clock.resync(position: 12.1, playing: true, at: later, latency: 0)

        XCTAssertEqual(clock.position(at: later), 12.0, accuracy: 0.001)
    }

    func testLargeDriftStillCorrects() {
        var clock = PositionClock()
        let start = Date(timeIntervalSince1970: 1_000)
        clock.resync(position: 12, playing: true, at: start, latency: 0)

        // Spotify reports 14 s when the clock predicts 12 s: real drift, so jump to it.
        clock.resync(position: 14, playing: true, at: start, latency: 0)

        XCTAssertEqual(clock.position(at: start), 14, accuracy: 0.001)
    }
}
