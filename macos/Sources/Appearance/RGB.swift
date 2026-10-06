import Foundation

/// A colour with components in 0...1. Plain values, so it can be stored as settings and tested.
public struct RGB: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Perceived brightness, using the Rec. 709 weights.
    public var luma: Double { 0.2126 * red + 0.7152 * green + 0.0722 * blue }

    /// Spread between the strongest and weakest channel: 0 for grey, 1 for pure colour.
    public var chroma: Double { max(red, green, blue) - min(red, green, blue) }

    func distance(to other: RGB) -> Double {
        let dr = red - other.red
        let dg = green - other.green
        let db = blue - other.blue
        return (dr * dr + dg * dg + db * db).squareRoot()
    }
}
