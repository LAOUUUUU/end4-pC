import XCTest
@testable import WidgetsCore

final class CPUUsageTests: XCTestCase {
    func testAllBusyIsOneHundredPercent() {
        // user, system, idle, nice: 100 busy ticks, no idle ticks.
        XCTAssertEqual(CPUUsage.percent(previous: [0, 0, 0, 0], current: [60, 40, 0, 0]), 100, accuracy: 0.001)
    }

    func testHalfIdleIsFiftyPercent() {
        XCTAssertEqual(CPUUsage.percent(previous: [0, 0, 0, 0], current: [30, 20, 50, 0]), 50, accuracy: 0.001)
    }

    func testNoTicksSinceLastSampleIsZero() {
        XCTAssertEqual(CPUUsage.percent(previous: [5, 5, 5, 5], current: [5, 5, 5, 5]), 0)
    }
}

final class MemoryUsageTests: XCTestCase {
    func testUsedPercentOfTotal() {
        XCTAssertEqual(MemoryUsage.percent(usedBytes: 8, totalBytes: 16), 50, accuracy: 0.001)
    }

    func testNeverAboveOneHundredOrBelowZero() {
        XCTAssertEqual(MemoryUsage.percent(usedBytes: 20, totalBytes: 16), 100, accuracy: 0.001)
        XCTAssertEqual(MemoryUsage.percent(usedBytes: 1, totalBytes: 0), 0)
    }
}

final class CountdownTests: XCTestCase {
    func testRemainingCountsDownFromDuration() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = Countdown(seconds: 300)
        timer.start(at: start)

        XCTAssertEqual(timer.remaining(at: start), 300, accuracy: 0.001)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(90)), 210, accuracy: 0.001)
    }

    func testFinishesAtZeroAndStaysThere() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = Countdown(seconds: 60)
        timer.start(at: start)

        XCTAssertFalse(timer.isFinished(at: start.addingTimeInterval(59)))
        XCTAssertTrue(timer.isFinished(at: start.addingTimeInterval(60)))
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(500)), 0)
    }

    func testNotRunningIsNotFinished() {
        XCTAssertFalse(Countdown(seconds: 60).isFinished(at: Date()))
    }

    func testCancelStopsIt() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = Countdown(seconds: 60)
        timer.start(at: start)
        timer.cancel()

        XCTAssertFalse(timer.isFinished(at: start.addingTimeInterval(120)))
    }
}

final class TodoListTests: XCTestCase {
    func testAddTrimsAndRejectsBlank() {
        var list = TodoList()

        list.add("  buy milk  ")
        list.add("   ")

        XCTAssertEqual(list.items.map(\.text), ["buy milk"])
    }

    func testToggleAndCount() throws {
        var list = TodoList()
        list.add("a")
        list.add("b")
        let first = try XCTUnwrap(list.items.first)

        list.toggle(first.id)

        XCTAssertEqual(list.completedCount, 1)
        XCTAssertTrue(list.items[0].done)
    }

    func testRemoveDropsTheItem() throws {
        var list = TodoList()
        list.add("a")
        let id = try XCTUnwrap(list.items.first?.id)

        list.remove(id)

        XCTAssertTrue(list.items.isEmpty)
    }

    func testRoundTripsThroughJSON() throws {
        var list = TodoList()
        list.add("keep")

        let decoded = try JSONDecoder().decode(TodoList.self, from: JSONEncoder().encode(list))

        XCTAssertEqual(decoded, list)
    }
}

final class ClockFormatTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_780_000_000) // 2026-05-28 20:26 UTC

    func testTwentyFourHourClock() {
        XCTAssertEqual(ClockFormat.time(date, in: TimeZone(identifier: "UTC")!, use24Hour: true), "20:26")
    }

    func testTwelveHourClock() {
        XCTAssertEqual(ClockFormat.time(date, in: TimeZone(identifier: "UTC")!, use24Hour: false), "8:26 PM")
    }

    func testSameInstantInAnotherZone() {
        let tokyo = ClockFormat.time(date, in: TimeZone(identifier: "Asia/Tokyo")!, use24Hour: true)

        XCTAssertEqual(tokyo, "05:26")
    }
}
