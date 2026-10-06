import XCTest
@testable import AudioVisualizer

final class VisualizerGeometryTests: XCTestCase {
    func testDotsLitProportionally() {
        XCTAssertEqual(VisualizerGeometry.litDots(level: 0, rows: 10), 0)
        XCTAssertEqual(VisualizerGeometry.litDots(level: 0.5, rows: 10), 5)
        XCTAssertEqual(VisualizerGeometry.litDots(level: 1, rows: 10), 10)
    }

    func testDotsClampOutOfRangeLevels() {
        XCTAssertEqual(VisualizerGeometry.litDots(level: 3, rows: 8), 8)
        XCTAssertEqual(VisualizerGeometry.litDots(level: -1, rows: 8), 0)
    }

    func testRadialAnglesCoverTheCircleEvenly() {
        XCTAssertEqual(VisualizerGeometry.radialAngle(index: 0, count: 4), 0, accuracy: 0.0001)
        XCTAssertEqual(VisualizerGeometry.radialAngle(index: 1, count: 4), .pi / 2, accuracy: 0.0001)
        XCTAssertEqual(VisualizerGeometry.radialAngle(index: 3, count: 4), 3 * .pi / 2, accuracy: 0.0001)
    }

    func testSmoothingKeepsLengthAndFlattensSpikes() {
        let spiky: [Float] = [0, 0, 1, 0, 0]

        let smoothed = VisualizerGeometry.smooth(spiky)

        XCTAssertEqual(smoothed.count, spiky.count)
        XCTAssertLessThan(smoothed[2], 1, "a single spike should be pulled down by its neighbours")
        XCTAssertGreaterThan(smoothed[1], 0, "neighbours of a spike should rise")
    }

    func testSmoothingLeavesEmptyAndFlatRowsAlone() {
        XCTAssertEqual(VisualizerGeometry.smooth([]), [])
        XCTAssertEqual(VisualizerGeometry.smooth([0.4, 0.4, 0.4]), [0.4, 0.4, 0.4])
    }
}
