import XCTest
@testable import LyricsCore

/// Fixtures copied from live responses of music.163.com (checked against the real API).
final class NetEaseProviderTests: XCTestCase {
    private let searchJSON = #"""
    {"result":{"songs":[
      {"id":1406633327,"name":"Blinding Lights","artists":[{"name":"The Weeknd"}],"duration":200045},
      {"id":1440628215,"name":"Blinding Lights (Major Lazer Remix)","artists":[{"name":"The Weeknd"},{"name":"Major Lazer"}],"duration":197961}
    ]},"code":200}
    """#

    private let lyricJSON = #"""
    {"lrc":{"version":3,"lyric":"[00:00.000] 作词 : Max Martin\n[00:01.000] 作曲 : Oscar Holter\n[00:05.492]I said ooh, I'm blinded by the lights\n[00:10.000]\n"},"code":200}
    """#

    func testParsesSearchSongs() throws {
        let songs = try NetEaseClient.decodeSongs(Data(searchJSON.utf8))

        XCTAssertEqual(songs.count, 2)
        XCTAssertEqual(songs[0], NetEaseSong(id: 1406633327, name: "Blinding Lights", artists: ["The Weeknd"], durationSeconds: 200.045))
        XCTAssertEqual(songs[1].artists, ["The Weeknd", "Major Lazer"])
    }

    func testReadsLRCTextFromLyricResponse() throws {
        let lrc = try XCTUnwrap(NetEaseClient.decodeLRC(Data(lyricJSON.utf8)))

        XCTAssertTrue(lrc.contains("[00:05.492]I said ooh"))
    }

    func testMissingLyricIsNil() throws {
        let json = #"{"nolyric":true,"code":200}"#

        XCTAssertNil(try NetEaseClient.decodeLRC(Data(json.utf8)))
    }

    func testDropsCreditLinesButKeepsRealLyrics() {
        let lines = [
            LyricLine(time: 0, text: "作词 : Max Martin"),
            LyricLine(time: 1, text: "作曲 : Oscar Holter"),
            LyricLine(time: 5.492, text: "I said ooh, I'm blinded by the lights"),
            LyricLine(time: 10, text: ""),
        ]

        let kept = NetEaseClient.removingCredits(lines)

        XCTAssertEqual(kept.map(\.text), ["I said ooh, I'm blinded by the lights", ""])
    }

    func testPicksSongWhoseDurationMatches() {
        let songs = [
            NetEaseSong(id: 1, name: "Blinding Lights", artists: ["The Weeknd"], durationSeconds: 300),
            NetEaseSong(id: 2, name: "Blinding Lights", artists: ["The Weeknd"], durationSeconds: 200.5),
        ]

        let best = NetEaseClient.bestMatch(in: songs, title: "Blinding Lights", artist: "The Weeknd", duration: 200)

        XCTAssertEqual(best?.id, 2)
    }

    func testRejectsSongWhoseDurationIsFarOff() {
        let songs = [NetEaseSong(id: 1, name: "Blinding Lights", artists: ["The Weeknd"], durationSeconds: 300)]

        XCTAssertNil(NetEaseClient.bestMatch(in: songs, title: "Blinding Lights", artist: "The Weeknd", duration: 200))
    }

    func testRejectsSongWithDifferentArtist() {
        let songs = [NetEaseSong(id: 1, name: "Blinding Lights", artists: ["Someone Else"], durationSeconds: 200)]

        XCTAssertNil(NetEaseClient.bestMatch(in: songs, title: "Blinding Lights", artist: "The Weeknd", duration: 200))
    }

    func testSearchURLEncodesQuery() throws {
        let url = try XCTUnwrap(NetEaseClient.searchURL(query: "Blinding Lights & more"))

        XCTAssertTrue(url.absoluteString.hasPrefix("https://music.163.com/api/search/get?"))
        XCTAssertTrue(url.absoluteString.contains("s=Blinding%20Lights%20%26%20more"))
        XCTAssertTrue(url.absoluteString.contains("type=1"))
    }
}
