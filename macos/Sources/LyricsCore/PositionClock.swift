import Foundation

/// Estimates the playback position between Spotify polls, so the lyrics can advance
/// smoothly without asking Spotify on every frame. Mirrors `currentPosition` and
/// `resync` in `services/LyricsService.qml`.
public struct PositionClock: Sendable {
    private var basePosition: Double = 0
    private var baseTime = Date.distantPast
    private var playing = false

    public init() {}

    /// Corrections smaller than this keep the predicted position. Reads jitter by a few hundred milliseconds.
    public static let snapThreshold = 0.25

    /// Records a position read from Spotify at local time `now`.
    /// `latency` is how long the read took. Half of it is added, since the position was sampled mid-way.
    /// A correction smaller than `snapThreshold` is ignored, so the lyrics do not jump on every poll.
    public mutating func resync(position reported: Double, playing: Bool, at now: Date, latency: Double = 0) {
        let corrected = reported + (playing ? latency / 2 : 0)
        if playing, self.playing, abs(self.position(at: now) - corrected) < Self.snapThreshold {
            // Keep the smooth prediction, but adopt the play state.
            self.playing = playing
            return
        }
        basePosition = corrected
        baseTime = now
        self.playing = playing
    }

    /// Estimated position at local time `now`. Frozen while paused.
    public func position(at now: Date) -> Double {
        guard playing else { return basePosition }
        return basePosition + now.timeIntervalSince(baseTime)
    }
}
