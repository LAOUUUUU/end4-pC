import Foundation

/// CPU load from two samples of Mach host ticks: user, system, idle, nice.
/// Mirrors the resources widget in the shell.
public enum CPUUsage {
    public static func percent(previous: [UInt32], current: [UInt32]) -> Double {
        guard previous.count == 4, current.count == 4 else { return 0 }
        let user = current[0] &- previous[0]
        let system = current[1] &- previous[1]
        let idle = current[2] &- previous[2]
        let nice = current[3] &- previous[3]
        let busy = Double(user) + Double(system) + Double(nice)
        let total = busy + Double(idle)
        guard total > 0 else { return 0 }
        return busy / total * 100
    }
}

/// Memory in use as a percentage of installed memory, kept within 0...100.
public enum MemoryUsage {
    public static func percent(usedBytes: UInt64, totalBytes: UInt64) -> Double {
        guard totalBytes > 0 else { return 0 }
        return min(100, Double(usedBytes) / Double(totalBytes) * 100)
    }
}

/// A countdown from a fixed length. Pure: the caller passes the current time.
public struct Countdown: Sendable {
    public let seconds: Double
    private var startedAt: Date?

    public init(seconds: Double) {
        self.seconds = seconds
    }

    public mutating func start(at now: Date) {
        startedAt = now
    }

    public mutating func cancel() {
        startedAt = nil
    }

    /// Seconds left. Equal to the full length before the timer starts, zero once it has run out.
    public func remaining(at now: Date) -> Double {
        guard let startedAt else { return seconds }
        return max(0, seconds - now.timeIntervalSince(startedAt))
    }

    /// True once a started countdown reaches zero. A timer that was never started, or was cancelled, is not finished.
    public func isFinished(at now: Date) -> Bool {
        guard startedAt != nil else { return false }
        return remaining(at: now) == 0
    }
}

/// One to-do entry.
public struct TodoItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public var done: Bool

    public init(id: UUID = UUID(), text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

/// A simple to-do list. Blank entries are rejected and text is trimmed.
public struct TodoList: Codable, Equatable, Sendable {
    public private(set) var items: [TodoItem] = []

    public init() {}

    public var completedCount: Int { items.filter(\.done).count }

    public mutating func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(text: trimmed))
    }

    public mutating func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].done.toggle()
    }

    public mutating func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
    }
}

/// Clock text for a time zone, as the shell's clock and world-clock widgets show it.
public enum ClockFormat {
    public static func time(_ date: Date, in zone: TimeZone, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
}
