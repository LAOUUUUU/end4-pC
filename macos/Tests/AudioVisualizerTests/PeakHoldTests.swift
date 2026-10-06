import XCTest
@testable import AudioVisualizer

final class PeakHoldTests: XCTestCase {
    func testPeakJumpsUpToNewLevel() {
        XCTAssertEqual(PeakHold.step(peak: 0.3, level: 0.8, fall: 0.02), 0.8, accuracy: 0.0001)
    }

    func testPeakFallsSlowlyWhenLevelDrops() {
        XCTAssertEqual(PeakHold.step(peak: 0.8, level: 0.1, fall: 0.02), 0.78, accuracy: 0.0001)
    }

    func testPeakNeverFallsBelowLevel() {
        XCTAssertEqual(PeakHold.step(peak: 0.5, level: 0.49, fall: 0.5), 0.49, accuracy: 0.0001)
    }
}
