import Foundation

/// Estimates the playback position between Spotify polls, so the lyrics can advance
/// smoothly without asking Spotify on every frame. Mirrors `currentPosition` and
/// `resync` in `services/LyricsService.qml`.
public struct PositionClock: Sendable {
    private var basePosition: Double = 0
    private var baseTime = Date.distantPast
    private var playing = false

    public init() {}

    /// Records a position read from Spotify at local time `now`.
    public mutating func resync(position: Double, playing: Bool, at now: Date) {
        basePosition = position
        baseTime = now
        self.playing = playing
    }

    /// Estimated position at local time `now`. Frozen while paused.
    public func position(at now: Date) -> Double {
        guard playing else { return basePosition }
        return basePosition + now.timeIntervalSince(baseTime)
    }
}
