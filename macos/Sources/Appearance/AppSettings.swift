import Foundation

/// Where the visualizer and lyric highlight take their colour from.
public enum ColorSource: String, Codable, CaseIterable, Sendable {
    /// Colours taken from the current track's cover art.
    case album
    /// `AppSettings.solidColor` for everything.
    case solid
}

/// How the bars are drawn.
public enum VisualizerStyle: String, Codable, CaseIterable, Sendable {
    /// Bars rising from the bottom, low frequencies on the left.
    case bars
    /// The same bars reflected around the centre.
    case mirror
}

/// User choices for the window. Stored as JSON in UserDefaults.
public struct AppSettings: Codable, Equatable, Sendable {
    public static let barCountChoices = [12, 16, 24, 32]
    public static let offsetRange: ClosedRange<Double> = -3...3

    public var barCount = 24
    public var style: VisualizerStyle = .bars
    public var showPeakCaps = true
    public var colorSource: ColorSource = .album
    public var solidColor = RGB(red: 0.2, green: 0.9, blue: 1.0)
    /// Seconds added to the playback position before choosing the lyric line. Negative shows lines later.
    public var lyricOffset = 0.0
    public var compactMode = false
    public var clickToSeek = true

    public init() {}

    /// The same settings with out-of-range values pulled back into the allowed set.
    public func normalized() -> AppSettings {
        var copy = self
        copy.barCount = Self.barCountChoices.min { abs($0 - barCount) < abs($1 - barCount) } ?? 24
        copy.lyricOffset = min(max(lyricOffset, Self.offsetRange.lowerBound), Self.offsetRange.upperBound)
        return copy
    }
}
