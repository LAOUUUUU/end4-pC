import Foundation

/// Picks the most common saturated colours from a set of pixels, for tinting the window from cover art.
public enum DominantColors {
    /// Buckets per channel when grouping similar colours.
    private static let levels = 15.0
    /// Colours closer than this (Euclidean distance over RGB) count as the same colour.
    private static let minimumDistance = 0.25

    /// Up to `count` colours, most prominent first. Near-black and grey pixels count for less.
    public static func pick(from pixels: [RGB], count: Int) -> [RGB] {
        guard count > 0, !pixels.isEmpty else { return [] }

        var buckets: [Int: (sum: RGB, count: Int)] = [:]
        for pixel in pixels {
            let key = bucketKey(pixel)
            let entry = buckets[key] ?? (RGB(red: 0, green: 0, blue: 0), 0)
            buckets[key] = (
                RGB(red: entry.sum.red + pixel.red, green: entry.sum.green + pixel.green, blue: entry.sum.blue + pixel.blue),
                entry.count + 1
            )
        }

        let ranked = buckets.values
            .map { entry -> (color: RGB, score: Double) in
                let average = RGB(
                    red: entry.sum.red / Double(entry.count),
                    green: entry.sum.green / Double(entry.count),
                    blue: entry.sum.blue / Double(entry.count)
                )
                // Dark and colourless means shadow or black border. Dark but saturated (pure blue) is kept.
                let darkPenalty = average.luma < 0.12 && average.chroma < 0.2 ? 0.05 : 1
                // Saturation counts quadratically, so a vivid minority beats a large grey area.
                return (average, Double(entry.count) * (0.02 + average.chroma * average.chroma) * darkPenalty)
            }
            .sorted { $0.score > $1.score }

        var picked: [RGB] = []
        for candidate in ranked where picked.count < count {
            if picked.allSatisfy({ $0.distance(to: candidate.color) >= minimumDistance }) {
                picked.append(candidate.color)
            }
        }
        return picked
    }

    private static func bucketKey(_ color: RGB) -> Int {
        let r = Int((color.red * levels).rounded())
        let g = Int((color.green * levels).rounded())
        let b = Int((color.blue * levels).rounded())
        return (r * 16 + g) * 16 + b
    }
}

extension DominantColors {
    /// The first colour with real saturation, or nil for a grey palette, so the caller can fall back.
    public static func accent(from palette: [RGB]) -> RGB? {
        palette.first { $0.chroma >= 0.15 }
    }
}
