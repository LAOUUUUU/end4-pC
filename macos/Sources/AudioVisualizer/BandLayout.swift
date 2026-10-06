import Foundation

/// Arranges band levels for different visualizer styles.
public enum BandLayout {
    /// The row reflected around its centre: low frequencies meet in the middle.
    public static func mirrored(_ levels: [Float]) -> [Float] {
        levels.reversed() + levels
    }
}
