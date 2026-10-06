import XCTest
@testable import LyricsCore

final class LyricsMatcherTests: XCTestCase {
    private func candidate(
        track: String?,
        artist: String?,
        synced: String? = "[00:01.00]line"
    ) -> LyricsCandidate {
        LyricsCandidate(trackName: track, artistName: artist, syncedLyrics: synced)
    }

    func testAcceptsExactTitleAndArtist() {
        XCTAssertTrue(LyricsMatcher.matches(
            candidate(track: "Blinding Lights", artist: "The Weeknd"),
            title: "Blinding Lights", artist: "The Weeknd"
        ))
    }

    func testIsCaseInsensitive() {
        XCTAssertTrue(LyricsMatcher.matches(
            candidate(track: "blinding lights", artist: "the weeknd"),
            title: "BLINDING LIGHTS", artist: "The Weeknd"
        ))
    }

    func testRejectsCandidateWithoutSyncedLyrics() {
        XCTAssertFalse(LyricsMatcher.matches(
            candidate(track: "Blinding Lights", artist: "The Weeknd", synced: nil),
            title: "Blinding Lights", artist: "The Weeknd"
        ))
        XCTAssertFalse(LyricsMatcher.matches(
            candidate(track: "Blinding Lights", artist: "The Weeknd", synced: ""),
            title: "Blinding Lights", artist: "The Weeknd"
        ))
    }

    func testRejectsDifferentArtist() {
        XCTAssertFalse(LyricsMatcher.matches(
            candidate(track: "Blinding Lights", artist: "Someone Else"),
            title: "Blinding Lights", artist: "The Weeknd"
        ))
    }

    func testAcceptsTitleWithExtraSuffix() {
        // Spotify often appends "- Remastered" and similar to titles.
        XCTAssertTrue(LyricsMatcher.matches(
            candidate(track: "Blinding Lights", artist: "The Weeknd"),
            title: "Blinding Lights - Remastered 2020", artist: "The Weeknd"
        ))
    }

    func testRejectsCandidateWithEmptyTrackName() {
        // The Python version treats an empty name as a substring of everything and matches it.
        XCTAssertFalse(LyricsMatcher.matches(
            candidate(track: "", artist: "The Weeknd"),
            title: "Blinding Lights", artist: "The Weeknd"
        ))
    }
}
