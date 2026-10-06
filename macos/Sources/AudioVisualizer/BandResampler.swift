import Foundation

/// Averages a row of band levels down (or repeats them up) to a chosen bar count.
public enum BandResampler {
    public static func resample(_ bands: [Float], to count: Int) -> [Float] {
        guard count > 0 else { return [] }
        guard !bands.isEmpty else { return [Float](repeating: 0, count: count) }
        guard bands.count != count else { return bands }

        let n = bands.count
        return (0..<count).map { i in
            let low = i * n / count
            let high = max(low + 1, (i + 1) * n / count)
            let slice = bands[low..<min(high, n)]
            return slice.reduce(0, +) / Float(slice.count)
        }
    }
}
