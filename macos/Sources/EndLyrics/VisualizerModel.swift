import AudioVisualizer
import Combine
import Foundation
import SpotifyKit

/// Number of frequency bars.
private let visualizerBandCount = 32

/// Shows Spotify's audio as bars. Taps the audio only while Spotify is playing.
@MainActor
final class VisualizerModel: ObservableObject {
    private static let decay: Float = 0.8
    private static let peakFall: Float = 0.015

    /// Smoothed band levels, each 0...1, drawn by `VisualizerView`.
    @Published private(set) var bands = [Float](repeating: 0, count: visualizerBandCount)
    /// Peak caps above each bar, 0...1, falling slowly after a bar drops.
    @Published private(set) var peaks = [Float](repeating: 0, count: visualizerBandCount)

    /// Bundle id prefix of the app whose audio is tapped (Spotify or Apple Music).
    private(set) var bundlePrefix = "com.spotify"

    private var tap: SpotifyAudioTap?
    private let shared = SharedBands()
    private var timer: Task<Void, Never>?
    private var subscription: AnyCancellable?
    /// True between "should be playing" and "should not be", independent of whether the tap is
    /// actually delivering audio right now. Used by the silence watchdog below.
    private var playing = false
    private var lastNonSilentAt = Date()

    /// Connects the visualizer to a source of "is Spotify playing" changes.
    func follow(_ isPlaying: Published<Bool>.Publisher) {
        subscription = isPlaying.removeDuplicates().sink { [weak self] playing in
            self?.setPlaying(playing)
        }
    }

    /// Switches to another app's audio. A running tap is restarted on the new app.
    func setBundlePrefix(_ prefix: String) {
        guard prefix != bundlePrefix else { return }
        bundlePrefix = prefix
        if tap != nil {
            stopTap()
            startTapIfNeeded()
        }
    }

    private func setPlaying(_ playing: Bool) {
        self.playing = playing
        if playing {
            startTapIfNeeded()
        } else {
            stopTap()
        }
    }

    private func startTapIfNeeded() {
        guard tap == nil else { return }

        let tap = SpotifyAudioTap()
        let shared = shared
        do {
            try tap.start(bundlePrefix: bundlePrefix) { samples in
                shared.consume(samples)
            }
        } catch {
            // Spotify may not be producing audio yet. The next playing change tries again.
            return
        }
        shared.setAnalyzer(SpectrumAnalyzer(
            fftSize: 1024,
            bandCount: visualizerBandCount,
            sampleRate: tap.sampleRate
        ))
        self.tap = tap
        startTimer()
    }

    private func stopTap() {
        tap?.stop()
        tap = nil
        shared.setAnalyzer(nil)
        timer?.cancel()
        timer = nil
        bands = [Float](repeating: 0, count: visualizerBandCount)
        peaks = [Float](repeating: 0, count: visualizerBandCount)
    }

    /// Redraws at about 30 frames per second, easing the bars toward the latest analysis.
    /// Also watches for the tap having gone silent while playback should be going: Spotify can swap
    /// which of its processes is actually producing audio (for example around a track change), which
    /// leaves a tap attached to the old, now-silent one with no "isPlaying changed" event to notice by.
    private func startTimer() {
        timer?.cancel()
        lastNonSilentAt = Date()
        timer = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let target = self.shared.latest()
                self.bands = zip(self.bands, target).map { previous, goal in
                    BandSmoother.step(previous: previous, target: goal, decay: Self.decay)
                }
                self.peaks = zip(self.peaks, self.bands).map { peak, level in
                    PeakHold.step(peak: peak, level: level, fall: Self.peakFall)
                }

                if target.contains(where: { $0 > 0.01 }) {
                    self.lastNonSilentAt = Date()
                } else if self.playing, Date().timeIntervalSince(self.lastNonSilentAt) > 3 {
                    self.lastNonSilentAt = Date()
                    self.stopTap()
                    self.startTapIfNeeded()
                }

                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
}

/// Holds the most recent analysis. Written on the tap's queue, read on the main actor.
private final class SharedBands: @unchecked Sendable {
    private let lock = NSLock()
    private var analyzer: SpectrumAnalyzer?
    private var bands = [Float](repeating: 0, count: visualizerBandCount)

    func setAnalyzer(_ analyzer: SpectrumAnalyzer?) {
        lock.lock()
        defer { lock.unlock() }
        self.analyzer = analyzer
        if analyzer == nil {
            bands = [Float](repeating: 0, count: visualizerBandCount)
        }
    }

    func consume(_ samples: [Float]) {
        lock.lock()
        let analyzer = self.analyzer
        lock.unlock()
        guard let analyzer else { return }

        let result = analyzer.bands(samples: samples)
        lock.lock()
        bands = result
        lock.unlock()
    }

    func latest() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return bands
    }
}
