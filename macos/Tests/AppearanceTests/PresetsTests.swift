import XCTest
@testable import Appearance

final class PresetsTests: XCTestCase {
    func testPresetNamesAreUniqueAndNotEmpty() {
        let names = ColorPreset.all.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
    }

    func testApplyingAPresetSetsASolidColour() {
        var settings = AppSettings()
        let rose = ColorPreset.all.first { $0.name == "Rose" }!

        rose.apply(to: &settings)

        XCTAssertEqual(settings.colorSource, .solid)
        XCTAssertEqual(settings.solidColor, rose.accent)
    }

    func testPresetsHaveDifferentAccents() {
        let accents = ColorPreset.all.map(\.accent)
        XCTAssertEqual(Set(accents.map { "\($0.red),\($0.green),\($0.blue)" }).count, accents.count)
    }
}

final class AnnouncerTests: XCTestCase {
    func testAnnouncesWhenTheTrackChanges() {
        XCTAssertTrue(TrackAnnouncer.shouldAnnounce(previous: "a", next: "b", enabled: true))
    }

    func testDoesNotRepeatTheSameTrack() {
        XCTAssertFalse(TrackAnnouncer.shouldAnnounce(previous: "a", next: "a", enabled: true))
    }

    func testDisabledNeverAnnounces() {
        XCTAssertFalse(TrackAnnouncer.shouldAnnounce(previous: "a", next: "b", enabled: false))
    }

    func testFirstTrackOfTheSessionIsAnnounced() {
        XCTAssertTrue(TrackAnnouncer.shouldAnnounce(previous: nil, next: "a", enabled: true))
    }
}

final class BackgroundImageSettingTests: XCTestCase {
    func testDefaultIsNoCustomImage() {
        XCTAssertNil(AppSettings().backgroundImagePath)
    }

    func testPathSurvivesJSON() throws {
        var settings = AppSettings()
        settings.backgroundImagePath = "/Users/me/Pictures/wall.jpg"

        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))

        XCTAssertEqual(decoded.backgroundImagePath, "/Users/me/Pictures/wall.jpg")
    }

    func testNotifyDefaultsOff() {
        XCTAssertFalse(AppSettings().notifyOnTrackChange)
    }
}

final class SettingsCompatibilityTests: XCTestCase {
    func testOlderSettingsWithMissingKeysKeepTheirValues() throws {
        // A settings blob from before the newest keys existed: only barCount is stored.
        let older = Data(#"{"barCount":16}"#.utf8)

        let decoded = try JSONDecoder().decode(AppSettings.self, from: older)

        XCTAssertEqual(decoded.barCount, 16)
        XCTAssertEqual(decoded.lyricScale, 1)
        XCTAssertFalse(decoded.notifyOnTrackChange)
    }
}

final class LaunchSettingTests: XCTestCase {
    func testMainMenuOpensAtLaunchByDefault() {
        XCTAssertTrue(AppSettings().openMainMenuAtLaunch)
    }

    func testOlderSettingsKeepTheLaunchDefault() throws {
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"barCount":12}"#.utf8))

        XCTAssertTrue(decoded.openMainMenuAtLaunch)
    }
}
