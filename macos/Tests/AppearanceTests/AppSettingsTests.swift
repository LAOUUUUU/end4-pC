import XCTest
@testable import Appearance

final class AppSettingsTests: XCTestCase {
    func testDefaults() {
        let settings = AppSettings()

        XCTAssertEqual(settings.barCount, 24)
        XCTAssertTrue(settings.showPeakCaps)
        XCTAssertEqual(settings.colorSource, .album)
        XCTAssertEqual(settings.lyricOffset, 0)
        XCTAssertFalse(settings.compactMode)
        XCTAssertTrue(settings.clickToSeek)
    }

    func testBarCountSnapsToAllowedChoices() {
        var settings = AppSettings()
        settings.barCount = 13
        XCTAssertEqual(settings.normalized().barCount, 12)
        settings.barCount = 30
        XCTAssertEqual(settings.normalized().barCount, 32)
        settings.barCount = 0
        XCTAssertEqual(settings.normalized().barCount, 12)
    }

    func testLyricOffsetIsClamped() {
        var settings = AppSettings()
        settings.lyricOffset = 9
        XCTAssertEqual(settings.normalized().lyricOffset, 3)
        settings.lyricOffset = -9
        XCTAssertEqual(settings.normalized().lyricOffset, -3)
    }

    func testRoundTripsThroughJSON() throws {
        var settings = AppSettings()
        settings.barCount = 16
        settings.colorSource = .solid
        settings.solidColor = RGB(red: 1, green: 0.5, blue: 0)
        settings.lyricOffset = -1.5

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
    }
}
