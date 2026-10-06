import Foundation

/// Layout maths for the visualizer styles that are not plain bars.
public enum VisualizerGeometry {
    /// Lit dots in a column for a level in 0...1.
    public static func litDots(level: Float, rows: Int) -> Int {
        let clamped = min(1, max(0, level))
        return Int((clamped * Float(rows)).rounded())
    }

    /// Angle of band `index` around a circle, starting at the top and going clockwise, in radians.
    public static func radialAngle(index: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }
        return Double(index) / Double(count) * 2 * .pi
    }

    /// Averages each level with its neighbours, so one loud band does not draw a spike.
    public static func smooth(_ levels: [Float]) -> [Float] {
        guard levels.count > 2 else { return levels }
        return levels.indices.map { i in
            let lower = levels[max(0, i - 1)]
            let upper = levels[min(levels.count - 1, i + 1)]
            return (lower + 2 * levels[i] + upper) / 4
        }
    }
}
