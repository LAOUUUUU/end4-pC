import XCTest
@testable import Appearance

final class PlaybackProgressTests: XCTestCase {
    func testFractionIsPositionOverDuration() {
        XCTAssertEqual(PlaybackProgress.fraction(position: 30, duration: 120), 0.25, accuracy: 0.0001)
    }

    func testFractionIsClampedToZeroAndOne() {
        XCTAssertEqual(PlaybackProgress.fraction(position: 200, duration: 120), 1)
        XCTAssertEqual(PlaybackProgress.fraction(position: -5, duration: 120), 0)
    }

    func testUnknownDurationGivesZero() {
        XCTAssertEqual(PlaybackProgress.fraction(position: 10, duration: 0), 0)
    }
}
