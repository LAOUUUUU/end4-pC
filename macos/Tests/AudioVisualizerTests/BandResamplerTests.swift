import XCTest
@testable import AudioVisualizer

final class BandResamplerTests: XCTestCase {
    func testHalvesCountByAveragingPairs() {
        let halved = BandResampler.resample([0.2, 0.4, 0.6, 0.8], to: 2)

        XCTAssertEqual(halved.count, 2)
        XCTAssertEqual(halved[0], 0.3, accuracy: 0.0001)
        XCTAssertEqual(halved[1], 0.7, accuracy: 0.0001)
    }

    func testSameCountIsUnchanged() {
        XCTAssertEqual(BandResampler.resample([0.1, 0.9], to: 2), [0.1, 0.9])
    }

    func testEmptyInputGivesZeros() {
        XCTAssertEqual(BandResampler.resample([], to: 3), [0, 0, 0])
    }
}
