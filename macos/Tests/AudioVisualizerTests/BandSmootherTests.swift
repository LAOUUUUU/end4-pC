import XCTest
@testable import AudioVisualizer

final class BandSmootherTests: XCTestCase {
    func testRisingLevelJumpsStraightToTarget() {
        XCTAssertEqual(BandSmoother.step(previous: 0.2, target: 0.9, decay: 0.85), 0.9, accuracy: 0.0001)
    }

    func testFallingLevelDecaysGradually() {
        XCTAssertEqual(BandSmoother.step(previous: 0.8, target: 0.0, decay: 0.5), 0.4, accuracy: 0.0001)
    }

    func testDecayNeverGoesBelowTarget() {
        XCTAssertEqual(BandSmoother.step(previous: 0.6, target: 0.5, decay: 0.5), 0.5, accuracy: 0.0001)
    }
}
