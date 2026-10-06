import Foundation

/// Tracks the highest recent level of a bar, drawn as a cap that drifts down slowly.
public enum PeakHold {
    /// Next cap height. Rises at once with the level, falls by `fall` per frame otherwise.
    public static func step(peak: Float, level: Float, fall: Float) -> Float {
        max(level, peak - fall)
    }
}
