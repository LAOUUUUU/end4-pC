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
        .executableTarget(
            name: "EndLyrics",
            dependencies: ["LyricsCore", "SpotifyKit", "AudioVisualizer"]
        ),
        .testTarget(name: "LyricsCoreTests", dependencies: ["LyricsCore"]),
        .testTarget(name: "SpotifyKitTests", dependencies: ["SpotifyKit"]),
        .testTarget(name: "AudioVisualizerTests", dependencies: ["AudioVisualizer"]),
    ],
    swiftLanguageModes: [.v5]
)
