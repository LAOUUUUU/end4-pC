import Foundation
import SpotifyKit

/// `EndLyrics --audio-check`: taps Spotify's audio for three seconds as the app itself,
/// writes the measured level to `audio-check.txt` in the caches folder, and exits.
/// Used to confirm the system-audio permission and the tap without any screen capture.
enum AudioCheck {
    static func run() -> Never {
        let meter = LevelMeter()
        let tap = SpotifyAudioTap()
        var outcome = "started"
        do {
            try tap.start { meter.add($0) }
        } catch {
            outcome = "failed: \(error)"
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            let report = "\(outcome) samples=\(meter.count) rms=\(meter.rms) sampleRate=\(tap.sampleRate)\n"
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("EndLyrics", isDirectory: true)
            try? FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
            try? report.write(to: caches.appendingPathComponent("audio-check.txt"), atomically: true, encoding: .utf8)
            tap.stop()
            exit(0)
        }
        dispatchMain()
    }
}

/// Running level of the samples delivered by the tap.
private final class LevelMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var sumOfSquares: Double = 0
    private(set) var count = 0

    func add(_ samples: [Float]) {
        lock.lock()
        defer { lock.unlock() }
        for sample in samples {
            sumOfSquares += Double(sample) * Double(sample)
        }
        count += samples.count
    }

    var rms: Double {
        lock.lock()
        defer { lock.unlock() }
        return count == 0 ? 0 : (sumOfSquares / Double(count)).squareRoot()
    }
}
