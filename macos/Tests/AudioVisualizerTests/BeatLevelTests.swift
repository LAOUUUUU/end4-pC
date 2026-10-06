import XCTest
@testable import AudioVisualizer

final class BeatLevelTests: XCTestCase {
    func testSilenceIsZero() {
        XCTAssertEqual(BeatLevel.bass(from: Array(repeating: 0, count: 32)), 0)
    }

    func testLowBandsDriveTheLevel() {
        var bands = [Float](repeating: 0, count: 32)
        for i in 0..<6 { bands[i] = 1 }

        XCTAssertEqual(BeatLevel.bass(from: bands), 1, accuracy: 0.0001)
    }

    func testHighBandsDoNotCount() {
        var bands = [Float](repeating: 0, count: 32)
        for i in 16..<32 { bands[i] = 1 }

        XCTAssertEqual(BeatLevel.bass(from: bands), 0, accuracy: 0.0001)
    }

    func testEmptyIsZero() {
        XCTAssertEqual(BeatLevel.bass(from: []), 0)
    }
}
