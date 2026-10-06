import Foundation

/// How far through a track playback is, for the progress bar.
public enum PlaybackProgress {
    public static func fraction(position: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, position / duration))
    }
}
