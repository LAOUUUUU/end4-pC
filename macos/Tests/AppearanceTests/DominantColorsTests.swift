import XCTest
@testable import Appearance

final class DominantColorsTests: XCTestCase {
    private let red = RGB(red: 1, green: 0, blue: 0)
    private let blue = RGB(red: 0, green: 0, blue: 1)
    private let green = RGB(red: 0, green: 1, blue: 0)
    private let black = RGB(red: 0.02, green: 0.02, blue: 0.02)

    func testEmptyImageGivesNoColors() {
        XCTAssertEqual(DominantColors.pick(from: [], count: 3), [])
    }

    func testSingleColorImageReturnsThatColorFirst() throws {
        let colors = DominantColors.pick(from: Array(repeating: red, count: 100), count: 3)

        let first = try XCTUnwrap(colors.first)
        XCTAssertEqual(first.red, 1, accuracy: 0.05)
        XCTAssertEqual(first.green, 0, accuracy: 0.05)
    }

    func testMostFrequentSaturatedColorComesFirst() throws {
        let pixels = Array(repeating: blue, count: 60) + Array(repeating: green, count: 40)

        let colors = DominantColors.pick(from: pixels, count: 2)

        XCTAssertEqual(colors.count, 2)
        XCTAssertGreaterThan(colors[0].blue, 0.9)
        XCTAssertGreaterThan(colors[1].green, 0.9)
    }

    func testNearBlackIsIgnoredWhenThereIsColour() throws {
        let pixels = Array(repeating: black, count: 900) + Array(repeating: red, count: 100)

        let first = try XCTUnwrap(DominantColors.pick(from: pixels, count: 1).first)

        XCTAssertGreaterThan(first.red, 0.9)
    }

    func testDistinctShadesOfOneColourDoNotFillTheResult() {
        // Two nearly identical reds and one blue: the second red is too close to the first.
        let nearRed = RGB(red: 0.95, green: 0.02, blue: 0.02)
        let pixels = Array(repeating: red, count: 50) + Array(repeating: nearRed, count: 50) + Array(repeating: blue, count: 20)

        let colors = DominantColors.pick(from: pixels, count: 2)

        XCTAssertEqual(colors.count, 2)
        XCTAssertGreaterThan(colors[1].blue, 0.9, "the second pick should be the blue, not another red")
    }

    func testVividColourBeatsLargeGreyArea() throws {
        // Most of a cover is pale grey; the green is small but vivid and should lead the palette.
        let grey = RGB(red: 0.86, green: 0.88, blue: 0.91)
        let green = RGB(red: 0.14, green: 0.47, blue: 0.33)
        let pixels = Array(repeating: grey, count: 80) + Array(repeating: green, count: 20)

        let first = try XCTUnwrap(DominantColors.pick(from: pixels, count: 1).first)

        XCTAssertGreaterThan(first.chroma, 0.2, "the vivid colour should lead, not the grey")
    }
}

final class AccentTests: XCTestCase {
    func testAccentIsTheFirstVividColour() {
        let grey = RGB(red: 0.9, green: 0.9, blue: 0.9)
        let green = RGB(red: 0.1, green: 0.6, blue: 0.3)

        XCTAssertEqual(DominantColors.accent(from: [grey, green]), green)
    }

    func testGreyOnlyPaletteHasNoAccent() {
        let grey = RGB(red: 0.9, green: 0.9, blue: 0.9)

        XCTAssertNil(DominantColors.accent(from: [grey, RGB(red: 0.6, green: 0.6, blue: 0.6)]))
    }

    func testEmptyPaletteHasNoAccent() {
        XCTAssertNil(DominantColors.accent(from: []))
    }
}

final class PaletteFidelityTests: XCTestCase {
    func testSingleColourComesBackAccurately() throws {
        let teal = RGB(red: 0.2, green: 0.6, blue: 0.55)

        let first = try XCTUnwrap(DominantColors.pick(from: Array(repeating: teal, count: 50), count: 1).first)

        XCTAssertEqual(first.red, teal.red, accuracy: 0.02)
        XCTAssertEqual(first.green, teal.green, accuracy: 0.02)
        XCTAssertEqual(first.blue, teal.blue, accuracy: 0.02)
    }

    func testReturnsFourColoursInOrderOfProminence() {
        let a = RGB(red: 0.9, green: 0.1, blue: 0.1)
        let b = RGB(red: 0.1, green: 0.9, blue: 0.1)
        let c = RGB(red: 0.1, green: 0.1, blue: 0.9)
        let d = RGB(red: 0.9, green: 0.8, blue: 0.1)
        let pixels = Array(repeating: a, count: 40) + Array(repeating: b, count: 30)
            + Array(repeating: c, count: 20) + Array(repeating: d, count: 10)

        let colors = DominantColors.pick(from: pixels, count: 4)

        XCTAssertEqual(colors.count, 4)
        XCTAssertEqual(colors[0].red, 0.9, accuracy: 0.05)
        XCTAssertEqual(colors[3].red, 0.9, accuracy: 0.05)
        XCTAssertEqual(colors[3].green, 0.8, accuracy: 0.05)
    }
}
