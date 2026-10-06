import Foundation

/// Lets bars jump up instantly and fall back gradually, so the display does not flicker.
public enum BandSmoother {
    /// Next displayed level. `decay` is the fraction of the previous level kept per frame.
    public static func step(previous: Float, target: Float, decay: Float) -> Float {
        max(target, previous * decay)
    }
}
