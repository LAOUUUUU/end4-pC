import XCTest
@testable import WidgetsCore

final class ClipboardHistoryTests: XCTestCase {
    func testAddPutsTheNewestFirst() {
        var history = ClipboardHistory()
        history.add("first")
        history.add("second")

        XCTAssertEqual(history.items, ["second", "first"])
    }

    func testReAddingAnExistingEntryMovesItToTheFrontInstead() {
        var history = ClipboardHistory()
        history.add("a")
        history.add("b")
        history.add("a")

        XCTAssertEqual(history.items, ["a", "b"])
    }

    func testBlankAndWhitespaceOnlyEntriesAreIgnored() {
        var history = ClipboardHistory()
        history.add("  ")
        history.add("")

        XCTAssertTrue(history.items.isEmpty)
    }

    func testOldestEntriesDropOffPastTheLimit() {
        var history = ClipboardHistory(limit: 3)
        for i in 1...4 { history.add("item\(i)") }

        XCTAssertEqual(history.items, ["item4", "item3", "item2"])
    }

    func testRemoveDropsOneEntry() {
        var history = ClipboardHistory()
        history.add("a")
        history.add("b")

        history.remove("a")

        XCTAssertEqual(history.items, ["b"])
    }

    func testClearEmptiesTheList() {
        var history = ClipboardHistory()
        history.add("a")
        history.clear()

        XCTAssertTrue(history.items.isEmpty)
    }

    func testRoundTripsThroughJSON() throws {
        var history = ClipboardHistory()
        history.add("keep me")

        let decoded = try JSONDecoder().decode(ClipboardHistory.self, from: JSONEncoder().encode(history))

        XCTAssertEqual(decoded, history)
    }
}
