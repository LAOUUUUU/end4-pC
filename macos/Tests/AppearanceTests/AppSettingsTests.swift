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

final class VisualizerStyleSettingTests: XCTestCase {
    func testDefaultStyleIsBars() {
        XCTAssertEqual(AppSettings().style, .bars)
    }

    func testMirrorStyleSurvivesJSON() throws {
        var settings = AppSettings()
        settings.style = .mirror

        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))

        XCTAssertEqual(decoded.style, .mirror)
    }
}

final class PlayerChoiceSettingTests: XCTestCase {
    func testDefaultPlayerIsSpotify() {
        XCTAssertEqual(AppSettings().player, .spotify)
    }

    func testPlayerChoiceSurvivesJSON() throws {
        var settings = AppSettings()
        settings.player = .appleMusic

        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))

        XCTAssertEqual(decoded.player, .appleMusic)
    }
}

final class MoreSettingsTests: XCTestCase {
    func testAllVisualizerStylesAreOffered() {
        XCTAssertEqual(VisualizerStyle.allCases, [.bars, .mirror, .dots, .wave, .radial, .blocks])
    }

    func testLyricScaleIsClampedAndDefaultsToOne() {
        XCTAssertEqual(AppSettings().lyricScale, 1)
        var settings = AppSettings()
        settings.lyricScale = 9
        XCTAssertEqual(settings.normalized().lyricScale, 1.5)
        settings.lyricScale = 0
        XCTAssertEqual(settings.normalized().lyricScale, 0.8)
    }

    func testBackgroundBlurIsClamped() {
        XCTAssertEqual(AppSettings().backgroundBlur, 40)
        var settings = AppSettings()
        settings.backgroundBlur = 500
        XCTAssertEqual(settings.normalized().backgroundBlur, 80)
        settings.backgroundBlur = -4
        XCTAssertEqual(settings.normalized().backgroundBlur, 0)
    }
}
