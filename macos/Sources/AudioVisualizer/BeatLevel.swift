import Foundation

/// A single 0...1 "bass" level from the lowest bands, used to make the cover pulse with the music.
public enum BeatLevel {
    /// Bands at the low end of the spectrum (the first six of 32 are roughly the bottom of the range).
    public static func bass(from bands: [Float], count: Int = 6) -> Float {
        let low = bands.prefix(count)
        guard !low.isEmpty else { return 0 }
        return min(1, max(0, low.reduce(0, +) / Float(low.count)))
    }
}
