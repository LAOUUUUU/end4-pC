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
    /// Columns of dots, lit up to the level.
    case dots
    /// A smooth line through the band levels.
    case wave
    /// Bars arranged around a circle.
    case radial
    /// Stacked LED-style blocks.
    case blocks
}

/// Which music app the window follows.
public enum PlayerChoice: String, Codable, CaseIterable, Sendable {
    case spotify
    case appleMusic
    /// Whichever app is playing, Spotify first.
    case automatic
}

/// User choices for the window. Stored as JSON in UserDefaults.
public struct AppSettings: Codable, Equatable, Sendable {
    public static let barCountChoices = [12, 16, 24, 32]
    public static let offsetRange: ClosedRange<Double> = -3...3
    public static let lyricScaleRange: ClosedRange<Double> = 0.8...1.5
    public static let blurRange: ClosedRange<Double> = 0...80

    public var barCount = 24
    public var style: VisualizerStyle = .bars
    public var player: PlayerChoice = .spotify
    public var showPeakCaps = true
    public var colorSource: ColorSource = .album
    public var solidColor = RGB(red: 0.2, green: 0.9, blue: 1.0)
    /// Seconds added to the playback position before choosing the lyric line. Negative shows lines later.
    public var lyricOffset = 0.0
    public var compactMode = false
    public var clickToSeek = true
    /// Multiplier on the lyric font sizes.
    public var lyricScale = 1.0
    /// Blur radius of the cover behind the window.
    public var backgroundBlur = 40.0
    /// File path of a custom background image. When set, it replaces the cover behind the window.
    public var backgroundImagePath: String?
    /// Post a notification when the track changes.
    public var notifyOnTrackChange = false
    /// Open the full-screen main menu when the app starts.
    public var openMainMenuAtLaunch = true
    /// Show the visualizer in the lyric panel.
    public var panelShowsVisualizer = true
    /// Show the progress bar, volume and playback controls in the lyric panel.
    public var panelShowsControls = true

    public init() {}

    /// Every key is optional when decoding, so settings saved by an older version keep their values
    /// and missing keys take the defaults. Without this, one missing key would reset every setting.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let defaults = AppSettings()
        barCount = try c.decodeIfPresent(Int.self, forKey: .barCount) ?? defaults.barCount
        style = try c.decodeIfPresent(VisualizerStyle.self, forKey: .style) ?? defaults.style
        showPeakCaps = try c.decodeIfPresent(Bool.self, forKey: .showPeakCaps) ?? defaults.showPeakCaps
        colorSource = try c.decodeIfPresent(ColorSource.self, forKey: .colorSource) ?? defaults.colorSource
        solidColor = try c.decodeIfPresent(RGB.self, forKey: .solidColor) ?? defaults.solidColor
        lyricOffset = try c.decodeIfPresent(Double.self, forKey: .lyricOffset) ?? defaults.lyricOffset
        compactMode = try c.decodeIfPresent(Bool.self, forKey: .compactMode) ?? defaults.compactMode
        clickToSeek = try c.decodeIfPresent(Bool.self, forKey: .clickToSeek) ?? defaults.clickToSeek
        lyricScale = try c.decodeIfPresent(Double.self, forKey: .lyricScale) ?? defaults.lyricScale
        backgroundBlur = try c.decodeIfPresent(Double.self, forKey: .backgroundBlur) ?? defaults.backgroundBlur
        backgroundImagePath = try c.decodeIfPresent(String.self, forKey: .backgroundImagePath)
        notifyOnTrackChange = try c.decodeIfPresent(Bool.self, forKey: .notifyOnTrackChange) ?? defaults.notifyOnTrackChange
        openMainMenuAtLaunch = try c.decodeIfPresent(Bool.self, forKey: .openMainMenuAtLaunch) ?? defaults.openMainMenuAtLaunch
        panelShowsVisualizer = try c.decodeIfPresent(Bool.self, forKey: .panelShowsVisualizer) ?? defaults.panelShowsVisualizer
        panelShowsControls = try c.decodeIfPresent(Bool.self, forKey: .panelShowsControls) ?? defaults.panelShowsControls
        player = try c.decodeIfPresent(PlayerChoice.self, forKey: .player) ?? defaults.player
    }

    private enum Keys: String, CodingKey {
        case barCount, style, showPeakCaps, colorSource, solidColor, lyricOffset, compactMode
        case clickToSeek, lyricScale, backgroundBlur, backgroundImagePath, notifyOnTrackChange, player, openMainMenuAtLaunch
        case panelShowsVisualizer, panelShowsControls
    }

    /// The same settings with out-of-range values pulled back into the allowed set.
    public func normalized() -> AppSettings {
        var copy = self
        copy.barCount = Self.barCountChoices.min { abs($0 - barCount) < abs($1 - barCount) } ?? 24
        copy.lyricOffset = min(max(lyricOffset, Self.offsetRange.lowerBound), Self.offsetRange.upperBound)
        copy.lyricScale = min(max(lyricScale, Self.lyricScaleRange.lowerBound), Self.lyricScaleRange.upperBound)
        copy.backgroundBlur = min(max(backgroundBlur, Self.blurRange.lowerBound), Self.blurRange.upperBound)
        return copy
    }
}
