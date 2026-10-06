import Foundation

/// One-tap accent colours. Applying one switches the accent to a solid colour.
public struct ColorPreset: Equatable, Sendable {
    public let name: String
    public let accent: RGB

    public init(name: String, accent: RGB) {
        self.name = name
        self.accent = accent
    }

    public static let all: [ColorPreset] = [
        ColorPreset(name: "Cyan", accent: RGB(red: 0.2, green: 0.9, blue: 1.0)),
        ColorPreset(name: "Rose", accent: RGB(red: 1.0, green: 0.42, blue: 0.62)),
        ColorPreset(name: "Amber", accent: RGB(red: 1.0, green: 0.74, blue: 0.22)),
        ColorPreset(name: "Mint", accent: RGB(red: 0.4, green: 0.95, blue: 0.66)),
        ColorPreset(name: "Violet", accent: RGB(red: 0.66, green: 0.5, blue: 1.0)),
        ColorPreset(name: "Mono", accent: RGB(red: 0.92, green: 0.92, blue: 0.92)),
    ]

    public func apply(to settings: inout AppSettings) {
        settings.colorSource = .solid
        settings.solidColor = accent
    }
}

/// Announces a track change once per track. Off unless the user turns it on.
public enum TrackAnnouncer {
    public static func shouldAnnounce(previous: String?, next: String, enabled: Bool) -> Bool {
        enabled && previous != next
    }
}
