import XCTest
@testable import AudioVisualizer

final class BandLayoutTests: XCTestCase {
    func testMirrorDoublesTheRowAroundTheCentre() {
        XCTAssertEqual(BandLayout.mirrored([0.2, 0.8]), [0.8, 0.2, 0.2, 0.8])
    }

    func testMirrorOfEmptyIsEmpty() {
        XCTAssertEqual(BandLayout.mirrored([]), [])
    }
}
