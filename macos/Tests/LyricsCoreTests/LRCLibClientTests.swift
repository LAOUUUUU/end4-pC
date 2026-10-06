import XCTest
@testable import LyricsCore

final class LRCLibClientTests: XCTestCase {
    func testBuildsThreeLookupURLsInFallbackOrder() {
        let urls = LRCLibClient.lookupURLs(title: "Blinding Lights", artist: "The Weeknd", duration: 200.7)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(
            urls[0].absoluteString,
            "https://lrclib.net/api/get?track_name=Blinding%20Lights&artist_name=The%20Weeknd&duration=200"
        )
        XCTAssertEqual(
            urls[1].absoluteString,
            "https://lrclib.net/api/search?track_name=Blinding%20Lights&artist_name=The%20Weeknd"
        )
        XCTAssertEqual(
            urls[2].absoluteString,
            "https://lrclib.net/api/search?q=Blinding%20Lights%20The%20Weeknd"
        )
    }

    func testEncodesAmpersandsSoTitlesCannotInjectParameters() {
        let urls = LRCLibClient.lookupURLs(title: "Rock & Roll", artist: "AC/DC", duration: 0)

        XCTAssertTrue(urls[1].absoluteString.contains("track_name=Rock%20%26%20Roll"))
        XCTAssertFalse(urls[1].absoluteString.contains("track_name=Rock & Roll"))
    }

    func testDecodesSingleObjectResponse() throws {
        let json = #"{"trackName":"Blinding Lights","artistName":"The Weeknd","syncedLyrics":"[00:01.00]hi"}"#

        let candidates = try LRCLibClient.decodeCandidates(Data(json.utf8))

        XCTAssertEqual(candidates, [
            LyricsCandidate(trackName: "Blinding Lights", artistName: "The Weeknd", syncedLyrics: "[00:01.00]hi"),
        ])
    }

    func testDecodesSearchArrayResponse() throws {
        let json = #"[{"trackName":"A","artistName":"B","syncedLyrics":null},{"trackName":"A","artistName":"B","syncedLyrics":"[00:02.00]x"}]"#

        let candidates = try LRCLibClient.decodeCandidates(Data(json.utf8))

        XCTAssertEqual(candidates.count, 2)
        XCTAssertNil(candidates[0].syncedLyrics)
        XCTAssertEqual(candidates[1].syncedLyrics, "[00:02.00]x")
    }
}
