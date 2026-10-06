import XCTest
@testable import LyricsCore

final class LyricsCacheTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EndLyricsTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testReturnsNilForUnknownTrack() {
        let cache = LyricsCache(directory: directory)

        XCTAssertNil(cache.lines(for: "spotify:track:unknown"))
    }

    func testStoresAndReturnsLinesForTrack() {
        let cache = LyricsCache(directory: directory)
        let lines = [LyricLine(time: 1.5, text: "hello")]

        cache.store(lines, for: "spotify:track:abc")

        XCTAssertEqual(cache.lines(for: "spotify:track:abc"), lines)
    }

    func testKeysWithSlashesAndColonsAreStoredSafely() {
        let cache = LyricsCache(directory: directory)
        let key = "spotify:track:../../escape"

        cache.store([LyricLine(time: 0, text: "x")], for: key)

        XCTAssertEqual(cache.lines(for: key)?.first?.text, "x")
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        XCTAssertEqual(contents.count, 1, "the key must map to exactly one file inside the cache directory")
    }

    func testCorruptEntryIsTreatedAsMissing() throws {
        let cache = LyricsCache(directory: directory)
        cache.store([LyricLine(time: 0, text: "x")], for: "k")
        let file = try XCTUnwrap(
            try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first
        )
        try Data("not json".utf8).write(to: file)

        XCTAssertNil(cache.lines(for: "k"))
    }
}
