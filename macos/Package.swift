// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EndLyrics",
    platforms: [.macOS("14.2")],
    products: [
        .executable(name: "EndLyrics", targets: ["EndLyrics"]),
    ],
    targets: [
        .target(name: "LyricsCore"),
        .target(name: "SpotifyKit", dependencies: ["AudioVisualizer"]),
        .target(name: "AudioVisualizer"),
        .target(name: "Appearance"),
        .target(name: "WidgetsCore"),
        .target(name: "AppleMusicKit", dependencies: ["SpotifyKit"]),
        .executableTarget(
            name: "EndLyrics",
            dependencies: ["LyricsCore", "SpotifyKit", "AudioVisualizer", "Appearance", "AppleMusicKit", "WidgetsCore"]
        ),
        .testTarget(name: "LyricsCoreTests", dependencies: ["LyricsCore"]),
        .testTarget(name: "SpotifyKitTests", dependencies: ["SpotifyKit"]),
        .testTarget(name: "AudioVisualizerTests", dependencies: ["AudioVisualizer"]),
        .testTarget(name: "AppearanceTests", dependencies: ["Appearance"]),
        .testTarget(name: "AppleMusicKitTests", dependencies: ["AppleMusicKit"]),
        .testTarget(name: "WidgetsCoreTests", dependencies: ["WidgetsCore"]),
    ],
    swiftLanguageModes: [.v5]
)
