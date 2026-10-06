import XCTest
@testable import LyricsCore

final class TrackChangePolicyTests: XCTestCase {
    func testLoadsWhenTrackIsNew() {
        XCTAssertTrue(TrackChangePolicy.shouldLoad(previous: nil, next: "a", afterError: false))
        XCTAssertTrue(TrackChangePolicy.shouldLoad(previous: "a", next: "b", afterError: false))
    }

    func testDoesNotReloadTheSameTrackWhenHealthy() {
        XCTAssertFalse(TrackChangePolicy.shouldLoad(previous: "a", next: "a", afterError: false))
    }

    func testReloadsTheSameTrackAfterAnError() {
        // A failed read leaves the window in an error state. A later good read must recover it.
        XCTAssertTrue(TrackChangePolicy.shouldLoad(previous: "a", next: "a", afterError: true))
    }
}
