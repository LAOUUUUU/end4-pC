import XCTest
@testable import SpotifyKit

final class SpotifyPlaybackParserTests: XCTestCase {
    private let sep = "\u{1F}"

    private func line(
        id: String = "spotify:track:abc",
        title: String = "Blinding Lights",
        artist: String = "The Weeknd",
        album: String = "After Hours",
        duration: String = "200040",
        position: String = "12.5",
        state: String = "playing",
        artwork: String = "https://i.scdn.co/image/ab67616d0000b273",
        shuffling: String = "false",
        repeating: String = "true",
        volume: String = "70"
    ) -> String {
        [id, title, artist, album, duration, position, state, artwork, shuffling, repeating, volume].joined(separator: sep)
    }

    func testParsesPlayingTrack() throws {
        let snapshot = try XCTUnwrap(SpotifyPlaybackParser.parse(line()))

        XCTAssertEqual(snapshot.trackID, "spotify:track:abc")
        XCTAssertEqual(snapshot.title, "Blinding Lights")
        XCTAssertEqual(snapshot.artist, "The Weeknd")
        XCTAssertEqual(snapshot.album, "After Hours")
        // Spotify reports the duration in milliseconds, despite the dictionary saying seconds.
        XCTAssertEqual(snapshot.duration, 200.04, accuracy: 0.001)
        XCTAssertEqual(snapshot.position, 12.5, accuracy: 0.001)
        XCTAssertEqual(snapshot.state, .playing)
    }

    func testParsesPausedAndStoppedStates() throws {
        XCTAssertEqual(try XCTUnwrap(SpotifyPlaybackParser.parse(line(state: "paused"))).state, .paused)
        XCTAssertEqual(try XCTUnwrap(SpotifyPlaybackParser.parse(line(state: "stopped"))).state, .stopped)
    }

    func testTitleMayContainCommasAndSpaces() throws {
        let snapshot = try XCTUnwrap(SpotifyPlaybackParser.parse(line(title: "Hello, World | Live")))

        XCTAssertEqual(snapshot.title, "Hello, World | Live")
    }

    func testEmptyOutputMeansNothingPlaying() {
        XCTAssertNil(SpotifyPlaybackParser.parse(""))
        XCTAssertNil(SpotifyPlaybackParser.parse("\n"))
    }

    func testMalformedOutputReturnsNil() {
        XCTAssertNil(SpotifyPlaybackParser.parse("only\(sep)three\(sep)fields"))
        XCTAssertNil(SpotifyPlaybackParser.parse(line(position: "not-a-number")))
    }

    func testParsesArtworkURL() throws {
        let snapshot = try XCTUnwrap(SpotifyPlaybackParser.parse(line()))

        XCTAssertEqual(snapshot.artworkURL?.absoluteString, "https://i.scdn.co/image/ab67616d0000b273")
    }

    func testMissingArtworkIsNilNotAnError() throws {
        let snapshot = try XCTUnwrap(SpotifyPlaybackParser.parse(line(artwork: "")))

        XCTAssertNil(snapshot.artworkURL)
    }

    func testParsesShuffleAndRepeatFlags() throws {
        let snapshot = try XCTUnwrap(SpotifyPlaybackParser.parse(line(shuffling: "true", repeating: "false")))

        XCTAssertTrue(snapshot.shuffling)
        XCTAssertFalse(snapshot.repeating)
    }

    func testParsesVolume() throws {
        XCTAssertEqual(try XCTUnwrap(SpotifyPlaybackParser.parse(line(volume: "35"))).volume, 35)
    }

    func testTenFieldOutputFromOlderScriptIsRejected() {
        let tenFields = ["id", "title", "artist", "album", "1000", "1", "playing", "https://x", "false", "false"].joined(separator: sep)

        XCTAssertNil(SpotifyPlaybackParser.parse(tenFields))
    }

    func testEightFieldOutputFromOlderScriptIsRejected() {
        let eightFields = ["id", "title", "artist", "album", "1000", "1", "playing", "https://x"].joined(separator: sep)

        XCTAssertNil(SpotifyPlaybackParser.parse(eightFields))
    }

    func testUnknownStateReturnsNil() {
        XCTAssertNil(SpotifyPlaybackParser.parse(line(state: "buffering")))
    }

    func testEmptyTitleIsTreatedAsNoTrack() {
        // Spotify may report no current track (for example during an ad). Do not look up lyrics for it.
        XCTAssertNil(SpotifyPlaybackParser.parse(line(title: "")))
    }
}
