import XCTest
@testable import AppleMusicKit
import SpotifyKit

final class AppleMusicParserTests: XCTestCase {
    private let sep = "\u{1F}"

    private func line(
        id: String = "ABC123",
        name: String = "Blinding Lights",
        artist: String = "The Weeknd",
        album: String = "After Hours",
        duration: String = "200.04",
        position: String = "12.5",
        state: String = "playing",
        shuffle: String = "false",
        repeatMode: String = "off"
    ) -> String {
        [id, name, artist, album, duration, position, state, shuffle, repeatMode].joined(separator: sep)
    }

    func testParsesAppleMusicTrack() throws {
        let snapshot = try XCTUnwrap(AppleMusicParser.parse(line()))

        XCTAssertEqual(snapshot.trackID, "music:ABC123")
        XCTAssertEqual(snapshot.title, "Blinding Lights")
        XCTAssertEqual(snapshot.artist, "The Weeknd")
        XCTAssertEqual(snapshot.duration, 200.04, accuracy: 0.001)
        XCTAssertEqual(snapshot.position, 12.5, accuracy: 0.001)
        XCTAssertEqual(snapshot.state, .playing)
        XCTAssertNil(snapshot.artworkURL, "Apple Music does not expose a cover URL")
    }

    func testRepeatIsOnForOneOrAll() throws {
        XCTAssertFalse(try XCTUnwrap(AppleMusicParser.parse(line(repeatMode: "off"))).repeating)
        XCTAssertTrue(try XCTUnwrap(AppleMusicParser.parse(line(repeatMode: "one"))).repeating)
        XCTAssertTrue(try XCTUnwrap(AppleMusicParser.parse(line(repeatMode: "all"))).repeating)
    }

    func testShuffleFlag() throws {
        XCTAssertTrue(try XCTUnwrap(AppleMusicParser.parse(line(shuffle: "true"))).shuffling)
    }

    func testEmptyNameIsNoTrack() {
        XCTAssertNil(AppleMusicParser.parse(line(name: "")))
    }

    func testWrongFieldCountIsRejected() {
        XCTAssertNil(AppleMusicParser.parse(["a", "b", "c"].joined(separator: sep)))
    }
}
