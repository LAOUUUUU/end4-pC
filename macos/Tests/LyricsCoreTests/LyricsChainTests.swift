import XCTest
@testable import LyricsCore

/// Test double that answers with a fixed result and counts how often it was asked.
private final class FakeProvider: LyricsProvider, @unchecked Sendable {
    let name: String
    private let result: [LyricLine]?
    private let lock = NSLock()
    private(set) var calls = 0

    init(name: String, result: [LyricLine]?) {
        self.name = name
        self.result = result
    }

    func fetch(title: String, artist: String, duration: Double) async -> [LyricLine]? {
        lock.lock()
        calls += 1
        lock.unlock()
        return result
    }
}

final class LyricsChainTests: XCTestCase {
    private let lines = [LyricLine(time: 1, text: "hello")]

    func testFirstProviderWithLyricsWins() async {
        let first = FakeProvider(name: "first", result: lines)
        let second = FakeProvider(name: "second", result: [LyricLine(time: 2, text: "other")])
        let chain = LyricsChain(providers: [first, second])

        let found = await chain.lyrics(title: "t", artist: "a", duration: 100)

        XCTAssertEqual(found?.provider, "first")
        XCTAssertEqual(found?.lines, lines)
        XCTAssertEqual(second.calls, 0, "later providers are not asked once one has answered")
    }

    func testFallsThroughToNextProviderWhenFirstHasNothing() async {
        let first = FakeProvider(name: "first", result: nil)
        let second = FakeProvider(name: "second", result: lines)
        let chain = LyricsChain(providers: [first, second])

        let found = await chain.lyrics(title: "t", artist: "a", duration: 100)

        XCTAssertEqual(found?.provider, "second")
    }

    func testEmptyResultCountsAsNothingFound() async {
        let first = FakeProvider(name: "first", result: [])
        let second = FakeProvider(name: "second", result: lines)
        let chain = LyricsChain(providers: [first, second])

        let found = await chain.lyrics(title: "t", artist: "a", duration: 100)

        XCTAssertEqual(found?.provider, "second")
    }

    func testReturnsNilWhenEveryProviderFails() async {
        let chain = LyricsChain(providers: [FakeProvider(name: "a", result: nil), FakeProvider(name: "b", result: nil)])

        let found = await chain.lyrics(title: "t", artist: "a", duration: 100)

        XCTAssertNil(found)
    }
}
