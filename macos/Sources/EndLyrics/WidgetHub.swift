import Combine
import Darwin
import Foundation
import WidgetsCore

/// CPU and memory from Mach host statistics, sampled every two seconds. Ported from the shell's resources widget.
@MainActor
final class SystemStats: ObservableObject {
    @Published private(set) var cpuPercent = 0.0
    @Published private(set) var memoryPercent = 0.0

    private var previousTicks: [UInt32] = []
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
    }

    private func sample() {
        if let ticks = Self.cpuTicks() {
            if previousTicks.count == 4 {
                cpuPercent = CPUUsage.percent(previous: previousTicks, current: ticks)
            }
            previousTicks = ticks
        }
        memoryPercent = MemoryUsage.percent(
            usedBytes: Self.usedMemory(),
            totalBytes: ProcessInfo.processInfo.physicalMemory
        )
    }

    /// user, system, idle, nice: the order `CPUUsage` expects.
    private static func cpuTicks() -> [UInt32]? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return [info.cpu_ticks.0, info.cpu_ticks.1, info.cpu_ticks.2, info.cpu_ticks.3]
    }

    /// Active, wired and compressed pages, in bytes.
    private static func usedMemory() -> UInt64 {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pages = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return pages * UInt64(vm_kernel_page_size)
    }
}

/// A countdown that can pause the music when it finishes. Ported from the shell's timers widget.
@MainActor
final class CountdownModel: ObservableObject {
    @Published private(set) var remaining: Double = 0
    @Published private(set) var running = false
    @Published var pausesMusic = true

    /// Called once when the countdown reaches zero.
    var onFinish: (() -> Void)?

    private var countdown = Countdown(seconds: 0)
    private var ticker: Timer?

    func start(minutes: Int) {
        countdown = Countdown(seconds: Double(minutes) * 60)
        countdown.start(at: Date())
        running = true
        remaining = countdown.seconds
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    func cancel() {
        countdown.cancel()
        ticker?.invalidate()
        ticker = nil
        running = false
        remaining = 0
    }

    private func tick() {
        let now = Date()
        remaining = countdown.remaining(at: now)
        if countdown.isFinished(at: now) {
            cancel()
            onFinish?()
        }
    }
}

/// The to-do list, saved as JSON in UserDefaults.
@MainActor
final class TodoStore: ObservableObject {
    private static let key = "io.github.endlyrics.todo"

    @Published var list: TodoList {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(TodoList.self, from: data) {
            list = saved
        } else {
            list = TodoList()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}

/// Everything the widgets need, created once and shared with the full-screen menu.
@MainActor
final class WidgetHub: ObservableObject {
    let stats = SystemStats()
    let countdown = CountdownModel()
    let todo = TodoStore()

    /// Time zones shown in the world clock, in order.
    let worldClocks: [(label: String, zone: TimeZone)] = [
        ("Local", .current),
        ("Tokyo", TimeZone(identifier: "Asia/Tokyo") ?? .current),
        ("London", TimeZone(identifier: "Europe/London") ?? .current),
        ("New York", TimeZone(identifier: "America/New_York") ?? .current),
    ]
}
